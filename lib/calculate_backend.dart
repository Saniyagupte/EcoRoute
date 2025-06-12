import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:http/http.dart' as http;

import 'model.dart';

class RouteResult {
  final List<LatLng> routePoints;
  final List<LatLng> chargingStations;

  RouteResult(this.routePoints, this.chargingStations);
}

class CalculateBackend {
  final String carModel;
  final double batteryPercent;
  final double avgSpeed;
  final LatLng startPosition;
  final LatLng endPosition;
  late final double rate, capacity;

  CalculateBackend({
    required this.carModel,
    required this.batteryPercent,
    required this.avgSpeed,
    required this.startPosition,
    required this.endPosition,
  }) {
    rate = CarModelSpecs.getConsumptionRate(carModel);
    capacity = CarModelSpecs.getBatteryCapacity(carModel);
  }

  double getAvailableRangeInKm() => (batteryPercent / 100) * capacity / rate;

  Future<RouteResult> showRoute(GooglePlace googlePlace) async {
    final stations = await _fetchChargingStations(googlePlace);
    final stationNodes = _toNodes(stations);
    final start = GraphNode('start', startPosition);
    final end = GraphNode('end', endPosition);

    List<GraphNode> path = [start];
    List<LatLng> visitedStations = [];

    double battery = batteryPercent;
    LatLng current = startPosition;

    while (true) {
      final rangeKm = (battery / 100) * capacity / rate;
      final distToEnd = await _roadDistance(current, endPosition);

      if (distToEnd <= rangeKm) {
        path.add(end);
        break;
      }

      final next = _chooseStation(current, stationNodes, rangeKm, endPosition);
      if (next == null) throw Exception('No reachable station from $current');

      path.add(next);
      visitedStations.add(next.location);
      current = next.location;
      battery = 100;
    }

    final pf = DijkstraPathfinder();
    for (var n in path) pf.addNode(n);
    for (int i = 0; i < path.length - 1; i++) {
      final a = path[i], b = path[i + 1];
      final d = await _roadDistance(a.location, b.location);
      pf.addEdge(a, b, d);
    }

    final route = pf.shortestPath('start', 'end');

    List<LatLng> finalRoute = [];
    for (int i = 0; i < route.length - 1; i++) {
      final segment = await _getRoutePolyline(route[i].location, route[i + 1].location);
      if (finalRoute.isNotEmpty) segment.removeAt(0);
      finalRoute.addAll(segment);
    }

    return RouteResult(finalRoute, visitedStations);
  }

  Future<List<SearchResult>> _fetchChargingStations(GooglePlace googlePlace) async {
    const int sampleCount = 10;
    const int radiusInMeters = 5000;
    List<SearchResult> allResults = [];
    Set<String> seen = {};

    for (int i = 0; i <= sampleCount; i++) {
      final lat = startPosition.latitude + (endPosition.latitude - startPosition.latitude) * (i / sampleCount);
      final lng = startPosition.longitude + (endPosition.longitude - startPosition.longitude) * (i / sampleCount);

      final response = await googlePlace.search.getNearBySearch(
        Location(lat: lat, lng: lng),
        radiusInMeters,
        type: "charging_station",
      );

      if (response?.results != null) {
        for (final place in response!.results!) {
          if (place.placeId != null && !seen.contains(place.placeId)) {
            seen.add(place.placeId!);
            allResults.add(place);
          }
        }
      }

      await Future.delayed(const Duration(milliseconds: 300));
    }
    return allResults;
  }

  Future<double> _roadDistance(LatLng a, LatLng b) async {
    final apiKey = dotenv.env['GOOGLE_API_KEY'];
    if (apiKey == null) {
      throw Exception('GOOGLE_API_KEY not found in .env');
    }

    final origin = '${a.latitude},${a.longitude}';
    final destination = '${b.latitude},${b.longitude}';

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['routes'] != null &&
          data['routes'].isNotEmpty &&
          data['routes'][0]['legs'] != null &&
          data['routes'][0]['legs'].isNotEmpty) {
        final distanceMeters = data['routes'][0]['legs'][0]['distance']['value'];
        return distanceMeters / 1000.0;
      }
    }

    return _straightLineDistance(a, b);
  }

  Future<List<LatLng>> _getRoutePolyline(LatLng origin, LatLng destination) async {
    final apiKey = dotenv.env['GOOGLE_API_KEY'];
    if (apiKey == null) throw Exception('GOOGLE_API_KEY not set');

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final points = data['routes'][0]['overview_polyline']['points'];
        return _decodePolyline(points);
      }
    }

    return [origin, destination];
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  GraphNode? _chooseStation(LatLng from, List<GraphNode> stations, double maxKm, LatLng to) {
    final feasible = stations.where((s) => _straightLineDistance(from, s.location) <= maxKm).toList();
    feasible.sort((a, b) => _straightLineDistance(a.location, to).compareTo(_straightLineDistance(b.location, to)));
    return feasible.isNotEmpty ? feasible.first : null;
  }

  List<GraphNode> _toNodes(List<SearchResult> stations) {
    List<GraphNode> nodes = [];
    for (int i = 0; i < stations.length; i++) {
      final lat = stations[i].geometry?.location?.lat;
      final lng = stations[i].geometry?.location?.lng;
      if (lat != null && lng != null) {
        nodes.add(GraphNode("station_$i", LatLng(lat, lng)));
      }
    }
    return nodes;
  }

  double _straightLineDistance(LatLng start, LatLng end) {
    const R = 6371;
    final dLat = _toRadians(end.latitude - start.latitude);
    final dLon = _toRadians(end.longitude - start.longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(start.latitude)) * cos(_toRadians(end.latitude)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) => degree * pi / 180;
}

class GraphNode {
  final LatLng location;
  final String id;
  GraphNode(this.id, this.location);
}

class GraphEdge {
  final GraphNode from;
  final GraphNode to;
  final double weight;
  GraphEdge(this.from, this.to, this.weight);
}

class DijkstraPathfinder {
  final Map<String, GraphNode> nodes = {};
  final Map<String, List<GraphEdge>> edges = {};

  void addNode(GraphNode node) {
    nodes[node.id] = node;
    edges[node.id] = [];
  }

  void addEdge(GraphNode from, GraphNode to, double weight) {
    edges[from.id]?.add(GraphEdge(from, to, weight));
  }

  List<GraphNode> shortestPath(String startId, String endId) {
    final dist = <String, double>{};
    final prev = <String, String?>{};
    final visited = <String>{};
    final queue = <String>{};

    for (var node in nodes.keys) {
      dist[node] = double.infinity;
      queue.add(node);
    }
    dist[startId] = 0;

    while (queue.isNotEmpty) {
      final currentId = queue.reduce((a, b) => dist[a]! < dist[b]! ? a : b);
      queue.remove(currentId);
      visited.add(currentId);

      if (currentId == endId) break;

      for (final edge in edges[currentId]!) {
        if (visited.contains(edge.to.id)) continue;

        final alt = dist[currentId]! + edge.weight;
        if (alt < dist[edge.to.id]!) {
          dist[edge.to.id] = alt;
          prev[edge.to.id] = currentId;
        }
      }
    }

    List<GraphNode> path = [];
    String? current = endId;
    while (current != null) {
      path.insert(0, nodes[current]!);
      current = prev[current];
    }
    return path;
  }
}

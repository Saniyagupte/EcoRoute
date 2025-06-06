import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class JourneyPlannerGoogle extends StatefulWidget {
  final String carModel;
  final double batteryPercent;

  JourneyPlannerGoogle({
    required this.carModel,
    required this.batteryPercent,
  });

  @override
  _JourneyPlannerGoogleState createState() => _JourneyPlannerGoogleState();
}

class _JourneyPlannerGoogleState extends State<JourneyPlannerGoogle> {
  GoogleMapController? mapController;
  final startCtrl = TextEditingController();
  final endCtrl = TextEditingController();

  late GooglePlace googlePlace;
  List<AutocompletePrediction> startPredictions = [];
  List<AutocompletePrediction> endPredictions = [];

  LatLng? startLatLng;
  LatLng? endLatLng;

  final FocusNode _startFocusNode = FocusNode();
  final FocusNode _endFocusNode = FocusNode();

  // Markers for start and end locations
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // Ensure you have a .env file with GOOGLE_API_KEY=YOUR_API_KEY
    googlePlace = GooglePlace(dotenv.env['GOOGLE_API_KEY']!);
    print("GooglePlace initialized with API key");

    // Listen to focus changes to clear predictions when losing focus
    _startFocusNode.addListener(() {
      print("Start field focus changed: ${_startFocusNode.hasFocus}");
      if (!_startFocusNode.hasFocus) {
        // Delay clearing to allow onTap to register on prediction list items
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted) { // Check if the widget is still mounted before setState
            setState(() {
              startPredictions.clear();
              print("Start predictions cleared due to loss of focus");
            });
          }
        });
      }
    });

    _endFocusNode.addListener(() {
      print("End field focus changed: ${_endFocusNode.hasFocus}");
      if (!_endFocusNode.hasFocus) {
        // Delay clearing to allow onTap to register on prediction list items
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted) { // Check if the widget is still mounted before setState
            setState(() {
              endPredictions.clear();
              print("End predictions cleared due to loss of focus");
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    mapController?.dispose();
    startCtrl.dispose();
    endCtrl.dispose();
    _startFocusNode.dispose();
    _endFocusNode.dispose();
    super.dispose();
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    print("Map created");
  }

  void autoCompleteSearch(String value, bool isStart) async {
    print("autoCompleteSearch called for ${isStart ? "start" : "end"} with value: '$value'");
    if (value.isEmpty) {
      setState(() {
        if (isStart) {
          startPredictions = [];
          print("Start predictions cleared because input is empty");
        } else {
          endPredictions = [];
          print("End predictions cleared because input is empty");
        }
      });
      return;
    }

    var result = await googlePlace.autocomplete.get(value);

    if (result != null && result.predictions != null && mounted) {
      setState(() {
        if (isStart) {
          startPredictions = result.predictions!;
          print("Start predictions updated: ${startPredictions.length}");
        } else {
          endPredictions = result.predictions!;
          print("End predictions updated: ${endPredictions.length}");
        }
      });
    } else {
      print("Autocomplete API returned null or no predictions.");
      setState(() {
        if (isStart) startPredictions = [];
        else endPredictions = [];
      });
    }
  }

  Future<void> setPlace(String placeId, String description, bool isStart) async {
    print("setPlace called for ${isStart ? "start" : "end"} placeId: $placeId");
    FocusScope.of(context).unfocus(); // Dismiss the keyboard

    var details = await googlePlace.details.get(
      placeId,
      fields: "name,geometry,formatted_address",
    );

    if (details == null || details.result == null) {
      print("Place details not found for placeId: $placeId");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not get location details.")),
        );
      }
      return;
    }

    final geometry = details.result!.geometry;
    if (geometry == null || geometry.location == null) {
      print("Geometry not found for placeId: $placeId");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location coordinates not found for this place.")),
        );
      }
      return;
    }

    final lat = geometry.location!.lat!;
    final lng = geometry.location!.lng!;
    final fullAddress = details.result!.formattedAddress ?? description; // Use description if formattedAddress is null
    final latLng = LatLng(lat, lng);

    print("Selected place details: $fullAddress, lat: $lat, lng: $lng");

    if (mounted) {
      setState(() {
        if (isStart) {
          startCtrl.text = fullAddress;
          startLatLng = latLng;
          // Add/update start marker
          _markers.removeWhere((m) => m.markerId.value == "start");
          _markers.add(
            Marker(
              markerId: MarkerId("start"),
              position: startLatLng!,
              infoWindow: InfoWindow(title: fullAddress),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), // Optional: green for start
            ),
          );
          startPredictions.clear(); // Clear predictions after selection
          print("Start location set and predictions cleared");
        } else {
          endCtrl.text = fullAddress;
          endLatLng = latLng;
          // Add/update end marker
          _markers.removeWhere((m) => m.markerId.value == "end");
          _markers.add(
            Marker(
              markerId: MarkerId("end"),
              position: endLatLng!,
              infoWindow: InfoWindow(title: fullAddress),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), // Optional: red for end
            ),
          );
          endPredictions.clear(); // Clear predictions after selection
          print("End location set and predictions cleared");
        }
      });
    }

    // Animate camera to the newly selected location if it's the first one or both are set
    if (mapController != null) {
      if (startLatLng != null && endLatLng != null) {
        // Calculate bounds to show both markers
        LatLngBounds bounds = _boundsFromLatLngList([startLatLng!, endLatLng!]);
        mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100)); // Padding of 100
      } else if (latLng != null) {
        mapController!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));
      }
      print("Map camera animated");
    }
  }

  // Helper to calculate bounds for two or more LatLng points
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.latitude > x1!) x1 = latLng.latitude!; // FIX
        if (latLng.longitude < y0!) y0 = latLng.longitude!; // FIX
        if (latLng.longitude > y1!) y1 = latLng.longitude!; // FIX
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }


  Widget _buildInputField(TextEditingController controller,
      FocusNode focusNode,
      String label,
      bool isStart,
      List<AutocompletePrediction> predictions,) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: label,
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
            ),
            onChanged: (val) {
              // Only perform search if the input field is currently focused
              if (focusNode.hasFocus) {
                autoCompleteSearch(val, isStart);
              }
            },
            onTap: () {
              // When tapped, if there's text, show predictions again
              if (controller.text.isNotEmpty) {
                autoCompleteSearch(controller.text, isStart);
              }
            },
          ),
        ),
        // Display predictions only when the associated text field is focused
        if (focusNode.hasFocus && predictions.isNotEmpty)
          Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.only(top: 4.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    constraints: BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: predictions.length,
                      itemBuilder: (context, index) {
                        final p = predictions[index];
                        final structuredFormatting = p.structuredFormatting;

                        return ListTile(
                          leading: Icon(Icons.location_on_outlined,
                              color: Colors.grey.shade600),
                          title: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                  color: Colors.black, fontSize: 16),
                              children: [
                                TextSpan(
                                  text: structuredFormatting?.mainText ?? '',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                TextSpan(
                                  text: (structuredFormatting?.secondaryText !=
                                      null)
                                      ? ' ${structuredFormatting!
                                      .secondaryText!}'
                                      : '',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            print("Prediction tapped: ${structuredFormatting?.mainText}");
                            // Pass the description to setPlace for better info window title
                            setPlace(p.placeId!, p.description ?? structuredFormatting?.mainText ?? 'Selected Place', isStart);
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Powered by ',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12),
                        ),
                        Text(
                          'Google',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        // Use a FocusScope to unfocus all fields and clear predictions
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() {
            startPredictions.clear();
            endPredictions.clear();
            print("Predictions cleared due to outside tap");
          });
        },
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(19.0760, 72.8777), // Mumbai initial camera
                zoom: 12,
              ),
              myLocationEnabled: true,
              markers: _markers, // Use the _markers set
            ),
            Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  _buildInputField(startCtrl, _startFocusNode, "Start", true, startPredictions),
                  const SizedBox(height: 8),
                  _buildInputField(endCtrl, _endFocusNode, "Destination", false, endPredictions),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Car Model: ${widget.carModel}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Battery: ${widget.batteryPercent.round()}%',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (startLatLng == null || endLatLng == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                              Text('Please select both start and destination locations'),
                            ),
                          );
                          return;
                        }
                        print("Continue button pressed");
                        print("Start Coordinates: ${startLatLng?.latitude}, ${startLatLng?.longitude}");
                        print("End Coordinates: ${endLatLng?.latitude}, ${endLatLng?.longitude}");
                        // TODO: Now you have startLatLng and endLatLng, you can use them to:
                        // 1. Calculate a route (e.g., using Google Directions API)
                        // 2. Pass them to the next screen
                      },
                      child: const Text("Continue"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
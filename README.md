# ⚡ EcoRoute – Smart EV Route Planner

EcoRoute is an intelligent electric vehicle (EV) journey planner designed for in-car tablet interfaces. It helps EV drivers optimize long-distance travel by accounting for battery levels, car model efficiency, and strategically located charging stations. With real-time mapping and EV-specific logic, EcoRoute ensures you never run out of charge mid-trip.

---

##  Features

- **EV-Aware Routing**  
  Plan routes based on your specific car model and driving speed.  
  Factor in real-world battery consumption profiles.

- **Battery Percentage Input**  
  Start with current battery % to accurately estimate range.  
  Visualize consumption over journey duration.

- **Smart Charging Stops**  
  Automatically places charging stations at optimal points.  
  Avoids range anxiety with predictive routing and safe margins.

- **Map Integration**  
  Google Maps integration with current location, route, and markers.  
  Select start and end points via autocomplete.

- **Tablet-First Flutter UI**  
  Clean, in-dash look with large touch targets.  
  Rounded UI components and dark mode aesthetic.

---

##  How It Works

EcoRoute uses a combination of graph algorithms, real-time APIs, and EV-specific range logic to compute efficient routes.

###  Graph-Based Modeling

- Routes are modeled as a **dynamic graph**, where:
  - Nodes = Start, End, and intermediate **charging stations** (fetched using Google Places API)
  - Edges = **Weighted road distances** between reachable pairs (retrieved via Google Directions API)

###  Greedy Charging Strategy

- The app calculates **available driving range** from the input battery % using:
- A **greedy heuristic** selects the **nearest reachable charging station** that also minimizes distance to destination.

###  Dijkstra’s Algorithm

- Once the list of waypoints (start → stations → end) is finalized:
- A weighted graph is built from these nodes.
- **Dijkstra's algorithm** is applied to compute the shortest total path.
- Ensures optimality in road distance, not just feasibility.

###  Polyline Rendering

- For every segment (start → station, station → station, station → end), the app:
- Fetches real-time turn-by-turn directions via Google Directions API.
- Decodes the **overview polyline** and renders it using Google Maps Flutter SDK.

---

##  Tech Stack

- **Flutter** – cross-platform mobile development
- **Google Maps SDK** – map rendering and interaction
- **Google Places API** – fetch nearby EV charging stations
- **Google Directions API** – compute road distances and polylines
- **Custom Graph Structures** – `GraphNode`, `GraphEdge`, and `DijkstraPathfinder` classes for route planning
- **EV Battery Model** – per-model consumption rates and capacity for realistic range estimation

---

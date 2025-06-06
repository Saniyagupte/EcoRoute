import 'package:flutter/material.dart';
import 'journey_planner.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedCarModel;
  double batteryPercent = 50;

  final List<String> carModels = [
    'Tesla Model 3',
    'Nissan Leaf',
    'Chevy Bolt',
    'BMW i3',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87, // dark theme
      body: Center(
        child: Container(
          width: 350,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Car Model',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              SizedBox(height: 8),
              DropdownButton<String>(
                dropdownColor: Colors.grey[800],
                value: selectedCarModel,
                hint: Text('Choose model', style: TextStyle(color: Colors.white70)),
                isExpanded: true,
                items: carModels.map((model) {
                  return DropdownMenuItem(
                    value: model,
                    child: Text(model, style: TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedCarModel = val;
                  });
                },
              ),
              SizedBox(height: 20),
              Text(
                'Battery %',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              Slider(
                value: batteryPercent,
                min: 0,
                max: 100,
                divisions: 20,
                label: '${batteryPercent.round()}%',
                onChanged: (val) {
                  setState(() {
                    batteryPercent = val;
                  });
                },
                activeColor: Colors.greenAccent,
                inactiveColor: Colors.grey,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (selectedCarModel == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please select a car model')),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JourneyPlannerGoogle(
                        carModel: selectedCarModel!,
                        batteryPercent: batteryPercent,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  child: Text('Plan a Route', style: TextStyle(fontSize: 18)),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

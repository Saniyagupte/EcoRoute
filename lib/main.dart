import 'package:flutter/material.dart';
import 'package:eco_route/home_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(EcoRouteApp());
}

class EcoRouteApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoRoute',
      theme: ThemeData.dark(), // For in-dash feel
      home: HomeScreen(),
    );
  }
}

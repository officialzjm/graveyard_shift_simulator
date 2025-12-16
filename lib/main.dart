import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:graveyard_shift_simulator/models/path_structure.dart';
import 'package:graveyard_shift_simulator/screens/planner_screen.dart';


void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => PathModel(),
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.grey.shade900,
        useMaterial3: true,
      ),
      home: const PlannerScreen(),
    );
  }
}

// --------------------- FIELD VIEW ---------------------


// --------------------- PAINTER ---------------------
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:vector_math/vector_math.dart';
//Speed and Velocity Variables
//Inches per second , we will standarize to meters later
const double maxVelocity = 70;
const double maxAccel = 200; // im not sure what this should be
const double fieldHalf = 72.6;
const double trackWidth = 5.5;
const handleRadius = 2.0;

extension OffsetToVector2 on Offset {
  Vector2 toVector2() => Vector2(dx, dy);
}

num clamp(num x, num minVal, num maxVal) {
  return math.max(minVal, math.min(x, maxVal));
}
double fmod(double a, double b) {
  return a - b * (a / b).floor();
}


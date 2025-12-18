import 'package:flutter/material.dart';
import 'package:graveyard_shift_simulator/constants.dart';

Offset cubicPoint(
  Offset p0,
  Offset p1,
  Offset p2,
  Offset p3,
  double t,
) {
  final u = 1 - t;
  return p0 * (u * u * u) +
      p1 * (3 * u * u * t) +
      p2 * (3 * u * t * t) +
      p3 * (t * t * t);
}

Offset cubicDerivative(
  Offset p0,
  Offset p1,
  Offset p2,
  Offset p3,
  double t,
) {
  final u = 1 - t;
  return (p1 - p0) * (3 * u * u) +
         (p2 - p1) * (6 * u * t) +
         (p3 - p2) * (3 * t * t);
}

Color velocityToColor(double v) {
  final t = ((v - 0) / (maxVelocity - 0)).clamp(0.0, 1.0); //min veloc: 0
  return Color.lerp(Colors.red, Colors.green, t)!;
}

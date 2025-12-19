import 'package:flutter/material.dart';
import 'package:graveyard_shift_simulator/constants.dart';
import 'package:graveyard_shift_simulator/models/path_structure.dart';

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

double cubicBezierLength(
  Offset p0,
  Offset p1,
  Offset p2,
  Offset p3, {
  int samples = 50,
}) {
  double length = 0.0;
  Offset prev = p0;

  for (int i = 1; i <= samples; i++) {
    final t = i / samples;
    final curr = cubicPoint(p0, p1, p2, p3, t);
    length += (curr - prev).distance;
    prev = curr;
  }

  return length;
}

Offset? positionAtTauNormalizedByDistance(
  List<Waypoint> waypoints,
  double tau, {
  int samplesPerSegment = 50,
}) {
  if (waypoints.length < 2) return null;

  // Clamp tau
  tau = tau.clamp(0.0, 1.0);

  // ---- Step 1: compute lengths per segment ----
  final segmentLengths = <double>[];
  double totalLength = 0.0;

  for (int i = 0; i < waypoints.length - 1; i++) {
    final w0 = waypoints[i];
    final w1 = waypoints[i + 1];

    // If no handles, treat as straight line
    final p0 = w0.pos;
    final p3 = w1.pos;
    final p1 = w0.handleOut ?? p0;
    final p2 = w1.handleIn ?? p3;

    final len = cubicBezierLength(
      p0,
      p1,
      p2,
      p3,
      samples: samplesPerSegment,
    );

    segmentLengths.add(len);
    totalLength += len;
  }

  if (totalLength <= 0) return waypoints.first.pos;

  // ---- Step 2: target distance along path ----
  double targetDist = tau * totalLength;

  // ---- Step 3: find the segment ----
  for (int i = 0; i < segmentLengths.length; i++) {
    final segLen = segmentLengths[i];

    if (targetDist <= segLen) {
      // ---- Step 4: convert distance → local t ----
      final w0 = waypoints[i];
      final w1 = waypoints[i + 1];

      final p0 = w0.pos;
      final p3 = w1.pos;
      final p1 = w0.handleOut ?? p0;
      final p2 = w1.handleIn ?? p3;

      // Walk along this segment until we reach targetDist
      double walked = 0.0;
      Offset prev = p0;

      for (int s = 1; s <= samplesPerSegment; s++) {
        final t = s / samplesPerSegment;
        final curr = cubicPoint(p0, p1, p2, p3, t);
        final d = (curr - prev).distance;

        if (walked + d >= targetDist) {
          final remaining = targetDist - walked;
          final ratio = remaining / d;
          return Offset.lerp(prev, curr, ratio)!;
        }

        walked += d;
        prev = curr;
      }

      return p3;
    }

    targetDist -= segLen;
  }

  return waypoints.last.pos;
}

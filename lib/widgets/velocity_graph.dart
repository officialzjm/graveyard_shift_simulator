import 'package:flutter/material.dart';
import 'package:graveyard_shift_simulator/models/path_structure.dart';

class VelocityGraphPainter extends CustomPainter {
  final List<VelocityPoint> points;
  final double minV;
  final double maxV;

  VelocityGraphPainter({
    required this.points,
    required this.minV,
    required this.maxV,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.lightBlueAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.orangeAccent
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;

    // Grid
    for (double x = 0; x <= size.width; x += size.width / 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += size.height / 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Axes
    final axisPaint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), axisPaint);
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axisPaint);

    if (points.length < 2) return;

    // Convert points to screen coordinates
    final pathPoints = <Offset>[];
    for (final point in points) {
      final x = point.t * size.width;
      final yNorm = (point.v - minV) / (maxV - minV);
      final y = size.height * (1.0 - yNorm.clamp(0.0, 1.0));
      pathPoints.add(Offset(x, y));
    }

    // Draw curve
    final path = Path();
    path.addPolygon(pathPoints, false);
    canvas.drawPath(path, linePaint);

    // Draw points
    for (final point in pathPoints) {
      canvas.drawCircle(point, 6, pointPaint);
    }
  }

  @override
  bool shouldRepaint(VelocityGraphPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.minV != minV ||
      oldDelegate.maxV != maxV;
}

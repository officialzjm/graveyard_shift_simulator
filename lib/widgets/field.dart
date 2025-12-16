import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:graveyard_shift_simulator/models/path_structure.dart';

class FieldView extends StatefulWidget {
  final double tValue;
  const FieldView({super.key, this.tValue = 0.0});

  @override
  State<FieldView> createState() => _FieldViewState();
}

double fieldHalf = 72.6; // inches
const handleRadius = 2.0; // 2 inches

class _FieldViewState extends State<FieldView> {
  DragTargetInfo? dragging;

  ui.Image? fieldImage; // Field background

  @override
  void initState() {
    super.initState();
    _loadFieldImage();
  }

  Future<void> _loadFieldImage() async {
    final data = await rootBundle.load('assets/images/V5PBF.png');
    final bytes = data.buffer.asUint8List();
    final img = await decodeImageFromList(bytes);
    setState(() => fieldImage = img);
  }

  Offset toScreen(Offset logical, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scaleX = size.width / (fieldHalf * 2);
    final scaleY = size.height / (fieldHalf * 2);
    final dynamicScale = min(scaleX, scaleY);
    return center + logical * dynamicScale;
  }

  Offset toLogical(Offset screen, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scaleX = size.width / (fieldHalf * 2);
    final scaleY = size.height / (fieldHalf * 2);
    final dynamicScale = min(scaleX, scaleY);
    return (screen - center) / dynamicScale;
  }

  DragTargetInfo? _hitTest(Offset logical) {
    final waypoints = context.read<PathModel>().waypoints;
    for (int i = 0; i < waypoints.length; i++) {
      final s = waypoints[i];

      if ((s.pos - logical).distance <= handleRadius) {
        return DragTargetInfo(index: i, type: SegmentDragType.pos);
      }

      if (s.handleIn != null &&
          (s.handleIn! - logical).distance <= handleRadius) {
        return DragTargetInfo(index: i, type: SegmentDragType.handleIn);
      }

      if (s.handleOut != null &&
          (s.handleOut! - logical).distance <= handleRadius) {
        return DragTargetInfo(index: i, type: SegmentDragType.handleOut);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
      final pathModel = context.read<PathModel>();
      final waypoints = pathModel.waypoints;    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          setState(() {
            dragging = _hitTest(toLogical(details.localPosition, size));
          });
        },
        onDoubleTapDown: (details) {
          var realClickPos = toLogical(details.localPosition, size);
          if (waypoints.isEmpty) {
            final secondWaypointPos = realClickPos + Offset(10,10);
            pathModel.addWaypoint(Waypoint(pos: realClickPos, handleOut: realClickPos + Offset(0,10)));
            pathModel.addWaypoint(Waypoint(pos: secondWaypointPos, handleIn: secondWaypointPos + Offset(0,10)));
          } else {
            final prevLast = waypoints[waypoints.length - 2];
            final last = waypoints.last;
            final newHandleOut = last.pos + computeHandleOffset(prevLast.pos, last.pos, distanceFormula(realClickPos, last.pos));
            final updatedLast = Waypoint(pos: last.pos, handleIn: last.handleIn, handleOut: newHandleOut);
            pathModel.updateWaypoint(waypoints.length - 1, updatedLast);
            pathModel.addWaypoint(Waypoint(pos: realClickPos, handleIn: realClickPos + computeHandleOffset(realClickPos, waypoints.last.pos)));
          }
        },
        onSecondaryTapDown: (details) {
          var realClickPos = toLogical(details.localPosition, size);

          bool wasEmpty = waypoints.isEmpty;
          pathModel.addWaypoint(Waypoint(pos: realClickPos));

          if (wasEmpty) {
            pathModel.addWaypoint(Waypoint(pos: realClickPos + Offset(10,10)));
          }
        },
        onPanStart: (details) {
          final logical = toLogical(details.localPosition, size);
          dragging = _hitTest(logical);
        },
        onPanUpdate: (details) {
          if (dragging != null) {
            final newLogical = toLogical(details.localPosition, size);
            pathModel.updateWaypoint(dragging!.index, Waypoint(
              pos: dragging!.type == SegmentDragType.pos 
                  ? newLogical  
                  : waypoints[dragging!.index].pos,
              handleIn: dragging!.type == SegmentDragType.pos
                  ? (waypoints[dragging!.index].handleIn ?? Offset.zero) + (newLogical - waypoints[dragging!.index].pos)
                  : (dragging!.type == SegmentDragType.handleIn ? newLogical : waypoints[dragging!.index].handleIn),
              handleOut: dragging!.type == SegmentDragType.pos
                  ? (waypoints[dragging!.index].handleOut ?? Offset.zero) + (newLogical - waypoints[dragging!.index].pos)
                  : (dragging!.type == SegmentDragType.handleOut ? newLogical : waypoints[dragging!.index].handleOut),
            ));
          }
        },
        onPanEnd: (_) => dragging = null,
        child: CustomPaint(
          size: size,
          painter: _FieldPainter(
            toScreen: (o) => toScreen(o, size),
            waypoints: waypoints,
            fieldImage: fieldImage,
            tValue: widget.tValue,
          ),
        ),
      );
    });
  }
}

class _FieldPainter extends CustomPainter {
  final ui.Image? fieldImage;
  final List<Waypoint> waypoints;
  final Offset Function(Offset) toScreen; 
  final double tValue;

  _FieldPainter({
    this.fieldImage,
    required this.waypoints,
    required this.toScreen,
    required this.tValue,
  });


  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / (fieldHalf * 2);
    final scaleY = size.height / (fieldHalf * 2);
    final dynamicScale = min(scaleX, scaleY);

    // Draw field image
    if (fieldImage != null) {
      final center = Offset(size.width / 2, size.height / 2);
      final fieldLogicalSize = fieldHalf * 2;
      final destRect = Rect.fromCenter(
        center: center,
        width: fieldLogicalSize * dynamicScale,
        height: fieldLogicalSize * dynamicScale,
      );

      canvas.drawImageRect(
        fieldImage!,
        Rect.fromLTWH(0, 0, fieldImage!.width.toDouble(), fieldImage!.height.toDouble()),
        destRect,
        Paint(),
      );
    }

    final paintLine = Paint()
      ..color = Colors.lightBlueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 / dynamicScale;

    final paintHandle = Paint()
      ..color = Colors.orangeAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 / dynamicScale;

    final drawingRadius = handleRadius * dynamicScale; // 2 inches scaled

    for (int i = 0; i < waypoints.length - 1; i++) {
      if (waypoints[i].visible) {
        final waypoint1 = waypoints[i];
        final waypoint2 = waypoints[i+1];
        final waypoint1pos = toScreen(waypoint1.pos);
        final waypoint2pos = toScreen(waypoint2.pos);
        final control1 = waypoint1.handleOut != null ? toScreen(waypoint1.handleOut!) : null;
        final control2 = waypoint2.handleIn != null ? toScreen(waypoint2.handleIn!) : null;

        if (control1 != null && control2 != null) {
          final path = Path()
            ..moveTo(waypoint1pos.dx, waypoint1pos.dy)
            ..cubicTo(control1.dx, control1.dy, control2.dx, control2.dy, waypoint2pos.dx, waypoint2pos.dy);
          canvas.drawPath(path, paintLine);

          canvas.drawLine(waypoint1pos, control1, paintHandle);
          canvas.drawLine(waypoint2pos, control2, paintHandle);
          canvas.drawCircle(control1, drawingRadius, paintHandle);
          canvas.drawCircle(control2, drawingRadius, paintHandle);
        } else {
          canvas.drawLine(waypoint1pos, waypoint2pos, paintLine);
        }

        canvas.drawCircle(waypoint1pos, drawingRadius, paintHandle);
        canvas.drawCircle(waypoint2pos, drawingRadius, paintHandle);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FieldPainter old) => true;
}

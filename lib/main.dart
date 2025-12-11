import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:math';

void main() {
  runApp(const MyApp());
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
      home: const FieldScreen(),
    );
  }
}

class FieldScreen extends StatefulWidget {
  const FieldScreen({super.key});

  @override
  State<FieldScreen> createState() => _FieldScreenState();
}

class _FieldScreenState extends State<FieldScreen> {
  double tValue = 0.0; // 0..1 for robot preview
  double speedMin = 0.0;
  double speedMax = 200.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.black,
                    child: FieldView(
                      tValue: tValue,
                    ),
                  ),
                ),
                // Right-side panel (future controls)
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Colors.grey.shade800,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Command Panel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('(Sidebar for commands, sequence, and options)', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom toolbar
          // NEW
        SizedBox(
          height: 160,
          child: Material(
            elevation: 4,
            color: Colors.grey.shade800,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Robot Path Visualizer panel
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Robot Path Visualizer (t)', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('t = '),
                              Expanded(
                                child: Slider(
                                  value: tValue,
                                  onChanged: (v) => setState(() => tValue = v),
                                  min: 0,
                                  max: 1,
                                ),
                              ),
                              Text(tValue.toStringAsFixed(2)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () => setState(() => tValue = 0.0),
                                child: const Text('Reset t'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => setState(() => tValue = 1.0),
                                child: const Text('End t'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Speed profile panel
                  Container(
                    width: 320,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Speed Profile (min/max)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('min'),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: '0',
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                onChanged: (v) => setState(() => speedMin = double.tryParse(v) ?? 0.0),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('max'),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: '200',
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                onChanged: (v) => setState(() => speedMax = double.tryParse(v) ?? 200.0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(child: Center(child: Text('Speed graph preview (future)', style: TextStyle(color: Colors.white70)))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }
}

// --------------------- FIELD VIEW ---------------------
class FieldView extends StatefulWidget {
  final double tValue;
  const FieldView({super.key, this.tValue = 0.0});

  @override
  State<FieldView> createState() => _FieldViewState();
}

abstract class PathSegment {
  final Offset start;
  final Offset end;

  // Standard constructor (no change here)
  PathSegment({required this.start, required this.end});
}

class LineSegment extends PathSegment {
  LineSegment({required super.start, required super.end});
}

class BezierSegment extends PathSegment {
  final Offset control1;
  final Offset control2;

  BezierSegment({
    required super.start,
    required super.end,
    required this.control1,
    required this.control2,
  });
}

class RobotPath { List<PathSegment> segments = []; }

class EditableSegment {
  Offset start;
  Offset end;
  Offset? control1; // optional for Bezier
  Offset? control2; // optional for Bezier

  EditableSegment({
    required this.start,
    required this.end,
    this.control1,
    this.control2,
  });
}
double fieldHalf = 72.6; // inches
final pointRadius = 2.0; // 2 inches
class _FieldViewState extends State<FieldView> {
  RobotPath robotPath = RobotPath();
  List<EditableSegment> segments = [];
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

  void _updateRobotPath() {
    robotPath.segments.clear();
    for (var s in segments) {
      if (s.control1 != null && s.control2 != null) {
        robotPath.segments.add(BezierSegment(
          start: s.start,
          end: s.end,
          control1: s.control1!,
          control2: s.control2!,
        ));
      } else {
        robotPath.segments.add(LineSegment(start: s.start, end: s.end));
      }
    }
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

  DragTargetInfo? _hitTest(Offset logical, double dynamicScale) {
    final handleRadius = 2.0 * dynamicScale; // 2 inches in logical units
    for (int i = 0; i < segments.length; i++) {
      final s = segments[i];
      if ((s.start - logical).distance <= handleRadius) return DragTargetInfo(index: i, type: SegmentDragType.start);
      if ((s.end - logical).distance <= handleRadius) return DragTargetInfo(index: i, type: SegmentDragType.end);
      if (s.control1 != null && (s.control1! - logical).distance <= handleRadius) return DragTargetInfo(index: i, type: SegmentDragType.control1);
      if (s.control2 != null && (s.control2! - logical).distance <= handleRadius) return DragTargetInfo(index: i, type: SegmentDragType.control2);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;

      final scaleX = size.width / (fieldHalf * 2);
      final scaleY = size.height / (fieldHalf * 2);
      final dynamicScale = min(scaleX, scaleY);

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTapDown: (details) {
          setState(() {
            final clickPos = details.localPosition;
            Offset start;
            Offset end = toLogical(clickPos, size);

            if (segments.isEmpty) {
              start = end; // first point at click
            } else {
              start = segments.last.end; // chain from last end
            }

            segments.add(EditableSegment(
              start: start,
              end: end,
              control1: start + const Offset(5, 5),
              control2: end + const Offset(5, -5),
            ));

            _updateRobotPath();
          });
        },
        onSecondaryTapDown: (details) {
          setState(() {
            final clickPos = details.localPosition;
            Offset start;

            if (segments.isEmpty) start = toLogical(clickPos, size);
            else start = segments.last.end;

            segments.add(EditableSegment(
              start: start,
              end: toLogical(clickPos, size),
            ));

            _updateRobotPath();
          });
        },
        onPanStart: (details) {
          final logical = toLogical(details.localPosition, size);
          dragging = _hitTest(logical, dynamicScale);
        },
        onPanUpdate: (details) {
          if (dragging != null) {
            setState(() {
              final newLogical = toLogical(details.localPosition, size);
              final seg = segments[dragging!.index];

              switch (dragging!.type) {
                case SegmentDragType.start:
                  seg.start = newLogical;
                  break;
                case SegmentDragType.end:
                  seg.end = newLogical;
                  break;
                case SegmentDragType.control1:
                  seg.control1 = newLogical;
                  break;
                case SegmentDragType.control2:
                  seg.control2 = newLogical;
                  break;
              }

              _updateRobotPath();
            });
          }
        },
        onPanEnd: (_) => dragging = null,
        child: CustomPaint(
          size: size,
          painter: _FieldPainter(
            segments: segments,
            toScreen: (o) => toScreen(o, size),
            fieldImage: fieldImage,
          ),
        ),
      );
    });
  }
}

class _FieldPainter extends CustomPainter {
  final List<EditableSegment> segments;
  final ui.Image? fieldImage;
  final Offset Function(Offset) toScreen;

  _FieldPainter({
    required this.segments,
    required this.toScreen,
    this.fieldImage,
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

    // Draw segments and handles
    final paintLine = Paint()
      ..color = Colors.lightBlueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 / dynamicScale;

    final paintHandle = Paint()
      ..color = Colors.orangeAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 / dynamicScale;

    final handleRadius = pointRadius * dynamicScale; // 2 inches scaled

    for (var s in segments) {
      final start = toScreen(s.start);
      final end = toScreen(s.end);
      final control1 = s.control1 != null ? toScreen(s.control1!) : null;
      final control2 = s.control2 != null ? toScreen(s.control2!) : null;

      if (control1 != null && control2 != null) {
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(control1.dx, control1.dy, control2.dx, control2.dy, end.dx, end.dy);
        canvas.drawPath(path, paintLine);

        canvas.drawLine(start, control1, paintHandle);
        canvas.drawLine(end, control2, paintHandle);
        canvas.drawCircle(control1, handleRadius, paintHandle);
        canvas.drawCircle(control2, handleRadius, paintHandle);
      } else {
        canvas.drawLine(start, end, paintLine);
      }

      canvas.drawCircle(start, handleRadius, paintHandle);
      canvas.drawCircle(end, handleRadius, paintHandle);
    }
  }

  @override
  bool shouldRepaint(covariant _FieldPainter old) => true;
}



enum SegmentDragType { start, end, control1, control2 }

class DragTargetInfo {
  final SegmentDragType type;
  final int index;
  DragTargetInfo({required this.type, required this.index});
}

// --------------------- PAINTER ---------------------
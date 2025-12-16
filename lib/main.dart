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

class CommandRow extends StatefulWidget {
  final String title;

  const CommandRow({super.key, required this.title});

  @override
  State<CommandRow> createState() => _CommandRowState();
}

class _CommandRowState extends State<CommandRow> {
  double value = 0.5;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Left circle button
          IconButton(
            onPressed: () {
              // left action
            },
            icon: const Icon(Icons.remove_red_eye_outlined),
            color: Colors.lightBlueAccent,
            iconSize: 28,
          ),

          // Slider expands
          Expanded(
            child: Slider(
              value: value,
              onChanged: (v) => setState(() => value = v),
              min: 0,
              max: 1,
            ),
          ),

          // Right circle button
          IconButton(
            onPressed: () {
              // right action
            },
            icon: const Icon(Icons.add_circle),
            color: Colors.lightBlueAccent,
            iconSize: 28,
          ),
        ],
      ),
    );
  }
}

class FieldScreen extends StatefulWidget { //main UI
  const FieldScreen({super.key});

  @override
  State<FieldScreen> createState() => _FieldScreenState();
}
final items = List<String>.generate(30, (i) => 'Item $i'); // Sample data source

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
                      children: [
                        const Text('Command Panel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('(Sidebar for commands, sequence, and options)', style: TextStyle(color: Colors.white70)),
                        Expanded(
                          child: ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              return CommandRow(title: items[index]);
                            },
                          )
                        )
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

class Waypoint {
  Offset pos;
  Offset? handleIn;
  Offset? handleOut;

  Waypoint({
    required this.pos,
    this.handleIn,
    this.handleOut,
  });
}

double fieldHalf = 72.6; // inches
const handleRadius = 2.0; // 2 inches

double distanceFormula(Offset prevPos, Offset pos) {
  final dist = sqrt(pow((pos.dy-prevPos.dy),2) + pow((pos.dx-prevPos.dx),2));
  return dist;
}

Offset computeHandleOffset(Offset prevPos, Offset pos, [double? setLength]) {
  final angle = atan2(pos.dy - prevPos.dy, pos.dx - prevPos.dx);
  final effectiveLength = setLength ?? distanceFormula(prevPos, pos);
  return Offset.fromDirection(angle, effectiveLength/2.0);
}

class _FieldViewState extends State<FieldView> {
  List<Waypoint> waypoints = [];
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
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          setState(() {
            dragging = _hitTest(toLogical(details.localPosition, size));
          });
        },
        onDoubleTapDown: (details) {
          setState(() {
            var realClickPos = toLogical(details.localPosition, size);
            if (waypoints.isEmpty) {
              final secondWaypointPos = realClickPos + Offset(10,10);
              waypoints.add(Waypoint(pos: realClickPos, handleOut: realClickPos + Offset(0,10)));
              waypoints.add(Waypoint(pos: secondWaypointPos, handleIn: secondWaypointPos + Offset(0,10)));
            } else {
              final prevLastWaypoint = waypoints[waypoints.length-2];
              waypoints.last.handleOut = waypoints.last.pos + computeHandleOffset(prevLastWaypoint.pos, waypoints.last.pos, distanceFormula(realClickPos, waypoints.last.pos));
              waypoints.add(Waypoint(pos: realClickPos, handleIn: realClickPos + computeHandleOffset(realClickPos, waypoints.last.pos)));
            }
          });
        },
        onSecondaryTapDown: (details) {
          setState(() {
            var realClickPos = toLogical(details.localPosition, size);

            bool wasEmpty = waypoints.isEmpty;
            waypoints.add(Waypoint(pos: realClickPos));

            if (wasEmpty) {
              waypoints.add(Waypoint(pos: realClickPos + Offset(10,10)));
            }
          });
        },
        onPanStart: (details) {
          final logical = toLogical(details.localPosition, size);
          dragging = _hitTest(logical);
        },
        onPanUpdate: (details) {
          if (dragging != null) {
            setState(() {
              final newLogical = toLogical(details.localPosition, size);
              final waypoint = waypoints[dragging!.index];

              switch (dragging!.type) {
                case SegmentDragType.pos:
                  waypoint.pos = newLogical;
                  break;
                case SegmentDragType.handleIn: //rename control1
                  waypoint.handleIn = newLogical;
                  break;
                case SegmentDragType.handleOut:
                  waypoint.handleOut = newLogical;
                  break;
              }
            });
          }
        },
        onPanEnd: (_) => dragging = null,
        child: CustomPaint(
          size: size,
          painter: _FieldPainter(
            waypointList: waypoints,
            toScreen: (o) => toScreen(o, size),
            fieldImage: fieldImage,
          ),
        ),
      );
    });
  }
}

class _FieldPainter extends CustomPainter {
  final List<Waypoint> waypointList;
  final ui.Image? fieldImage;
  final Offset Function(Offset) toScreen; 

  _FieldPainter({
    required this.waypointList,
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

    final paintLine = Paint()
      ..color = Colors.lightBlueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 / dynamicScale;

    final paintHandle = Paint()
      ..color = Colors.orangeAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 / dynamicScale;

    final drawingRadius = handleRadius * dynamicScale; // 2 inches scaled

    for (int i = 0; i < waypointList.length - 1; i++) {
      final waypoint1 = waypointList[i];
      final waypoint2 = waypointList[i+1];
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

  @override
  bool shouldRepaint(covariant _FieldPainter old) => true;
}



enum SegmentDragType { pos, handleIn, handleOut }

class DragTargetInfo {
  final SegmentDragType type;
  final int index;
  DragTargetInfo({required this.type, required this.index});
}

// --------------------- PAINTER ---------------------
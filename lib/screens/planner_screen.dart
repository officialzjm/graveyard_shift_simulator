import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:graveyard_shift_simulator/models/path_structure.dart';
import 'package:graveyard_shift_simulator/widgets/explorer_row.dart';
import 'package:graveyard_shift_simulator/widgets/field.dart';
import 'package:graveyard_shift_simulator/widgets/velocity_graph.dart';



class PlannerScreen extends StatefulWidget { //main UI
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}
final items = List<String>.generate(30, (i) => 'Item $i'); // Sample data source

class _PlannerScreenState extends State<PlannerScreen> {
  double tValue = 0.0; // 0..1 for robot preview
  double speedMin = 0.0;
  double speedMax = 200.0;

  @override
  Widget build(BuildContext context) {
    final waypoints = context.watch<PathModel>().waypoints;
    return Scaffold(
      body: Column(
        children: [
          Container( //top toolbar
            height: 40,
            color: Colors.grey.shade900,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Planner',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                /*
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () {},
                ),
                */
              ],
            ),
          ),
          Expanded( // Outer Expanded for field+sidebar
  child: Row(
    children: [
      // Field - fixed
      ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 500,
          minHeight: 500,
          maxHeight: 900,
          maxWidth: 900,
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          color: Colors.black,
          child: FieldView(tValue: tValue),
        ),
      ),
      
      Expanded( 
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
                  itemCount: waypoints.length,
                  itemBuilder: (context, index) => ExplorerRow(index: index),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),

              // Replace the old speed profile Container with:
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
                      const Text('Velocity Graph', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              onTapDown: (details) {
                                final pathModel = context.read<PathModel>();
                                final t = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                                final v = speedMax - (details.localPosition.dy / constraints.maxHeight) * (speedMax - speedMin);
                                pathModel.addVelocityPoint(VelocityPoint(t: t, v: v.clamp(speedMin, speedMax)));
                              },
                              child: CustomPaint(
                                size: Size(constraints.maxWidth, constraints.maxHeight),
                                painter: VelocityGraphPainter(
                                  points: context.watch<PathModel>().velocityPoints,
                                  minV: speedMin,
                                  maxV: speedMax,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),

          // Bottom toolbar
          /*
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
          ),*/
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:graveyard_shift_simulator/models/path_structure.dart';

class ExplorerRow extends StatelessWidget {
  final int index;
  final value = .5;
  const ExplorerRow({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Consumer<PathModel>(
      builder: (context, pathModel, child) {
        final waypoint = pathModel.waypoints[index];
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              IconButton(
                onPressed: () => pathModel.setVisibility(index, !waypoint.visible),
                icon: Icon(
                  waypoint.visible
                      ? Icons.remove_red_eye
                      : Icons.remove_red_eye_outlined,
                ),
                color: Colors.lightBlueAccent,
                iconSize: 28,
              ),
              Expanded(child:Text('Waypoint $index', style: TextStyle(color: Colors.white70))) //expanded not really needed
            ],
          ),
        );
      },
    );
  }
}

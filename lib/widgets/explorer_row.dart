import 'package:flutter/material.dart';
import 'package:graveyard_shift_simulator/constants.dart';
import 'package:provider/provider.dart';
import 'package:graveyard_shift_simulator/models/path_structure.dart';

class WaypointRow extends StatelessWidget {
  final int index;
  final List<({int globalIndex, Command command})> wpCommands;
  final value = .5;
  const WaypointRow({super.key, required this.index, required this.wpCommands});

  @override
  Widget build(BuildContext context) {
    return Consumer<PathModel>(
      builder: (context, pathModel, child) {
        final waypoint = pathModel.waypoints[index];
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Row(
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
                  IconButton(
                    icon: Icon(Icons.delete),
                    color: Colors.redAccent,
                    onPressed:() => pathModel.removeWaypoint(index),
                    iconSize: 28,
                  ),
                  IconButton(
                    icon: Icon(
                      waypoint.reversed 
                        ? Icons.arrow_back 
                        : Icons.arrow_forward
                    ),
                    color: Colors.purpleAccent,
                    onPressed: () => pathModel.setReversed(index,!waypoint.reversed),
                    iconSize: 28,
                  ),
                  Expanded(
                    child: Slider(
                      value: waypoint.velocity,
                      onChanged: (v) => pathModel.setVelocity(index,v),
                      min: 0,
                      max: maxVelocity,
                    ),
                  ),
                  
                  SizedBox(width: 10),
                  Expanded(child:Text('Waypoint $index', style: TextStyle(color: Colors.white70))), //expanded not really needed
                  Consumer<CommandList>(
                    builder: (context, commandList, child) {
                      return IconButton(
                        onPressed: () => commandList.addCommand(
                          Command(t: 1.0, waypointIndex: index, name: CommandName.intake),
                        ),
                        icon: Icon(Icons.add_circle),
                        iconSize: 30,
                        color: Colors.pink,
                      );
                    },
                  ),
                ],
              ),
              for (final entry in wpCommands)
                CommandRow(
                  globalIndex: entry.globalIndex,
                  command: entry.command,
              ),
            ],
          ),
        );
      },
    );
  }
}
class CommandRow extends StatelessWidget {
  final int globalIndex;
  final Command command;

  const CommandRow({
    super.key,
    required this.globalIndex,
    required this.command,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CommandList>(
      builder: (context, commandList, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: IconButton(
                  icon: Icon(Icons.delete),
                  color: Colors.redAccent,
                  onPressed: () =>
                      commandList.removeCommand(globalIndex),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 8,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Distance along the path',
                    hintText: '0 < tau < 1',
                  ),
                  keyboardType:
                      TextInputType.numberWithOptions(decimal: true),
                  maxLength: 7,
                  onChanged: (v) {
                    final t = double.tryParse(v);
                    if (t != null) {
                      commandList.changeCmdT(globalIndex, t);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 20,
                child: DropdownButton<CommandName>(
                  value: command.name,
                  isExpanded: true,
                  onChanged: (newName) {
                    if (newName != null) {
                      commandList.modifyCommand(
                        globalIndex,
                        Command(
                          t: command.t,
                          waypointIndex: command.waypointIndex,
                          name: newName,
                        ),
                      );
                    }
                  },
                  items: CommandName.values.map((cmd) {
                    return DropdownMenuItem(
                      value: cmd,
                      child: Text(cmd.name),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

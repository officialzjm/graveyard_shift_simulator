import 'package:flutter/material.dart';
import 'package:graveyard_shift_simulator/constants.dart';
import 'package:provider/provider.dart';
import 'package:graveyard_shift_simulator/models/path_structure.dart';

class WaypointRow extends StatelessWidget {
  final int index;
  final List<Command> wpCommands;
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
              for (int i = 0; i < wpCommands.length; i++)
                CommandRow(index: i, command: wpCommands[i]),
            ],
          ),
        );
      },
    );
  }
}
class CommandRow extends StatelessWidget {
  final int index;
  final Command command;
  const CommandRow({super.key, required this.index, required this.command});

  @override
  Widget build(BuildContext context) {
    return Consumer<CommandList>(
      builder: (context, commandList, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [ 
              Expanded(
                flex: 1,
                child: Text('$index', style: TextStyle(color: Colors.white70)),
              ), //expanded not really needed
              Expanded(
                flex: 2,
                child: IconButton(
                  icon: Icon(Icons.delete),
                  color: Colors.redAccent,
                  onPressed:() => commandList.removeCommand(index),
                ),
              ),
              SizedBox(width: 10),
              //x2
              Expanded(
                flex: 8,
                child: TextField(
                  decoration: InputDecoration(labelText: 'Distance along the path', hintText: '0 < tau < 1'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  maxLength: 7,
                  onChanged: (v) => commandList.changeCmdT(index, double.parse(v)),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                flex: 20,
                child: DropdownButton<CommandName>(
                  value: command.name,
                  isExpanded: true,
                  onChanged: (CommandName? newName) {
                    if (newName != null) {
                      commandList.modifyCommand(index, Command(t: command.t, waypointIndex: i, name: newName));
                    }
                  },
                  items: CommandName.values.map((cmd) {
                    return DropdownMenuItem<CommandName>(
                      value: cmd,
                      child: Text(cmd.name),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(width: 10),
              Flexible(
                child: SizedBox(width: 100),
              ),
            ],
          ),
        );
      },
    );
  }
}
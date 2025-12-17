import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:graveyard_shift_simulator/models/path_structure.dart';

class WaypointRow extends StatelessWidget {
  final int index;
  final value = .5;
  const WaypointRow({super.key, required this.index});

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
class CommandRow extends StatelessWidget {
  final int index;
  const CommandRow({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Consumer<CommandList>(
      builder: (context, commandList, child) {
        final command = commandList.commands[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              
              Expanded(
                child: Text('Command $index', style: TextStyle(color: Colors.white70))), //expanded not really needed
              Expanded(
                child: TextField(
                  decoration: InputDecoration(labelText: 'Enter a number', hintText: 'Mobile Number'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  maxLength: 7,
                ),
              ),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(labelText: 'Enter a number', hintText: 'Mobile Number'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  maxLength: 7,
                  onChanged:(stringValue) =>  {
                    commandList.modifyCommand(index, Command(t: double.tryParse(stringValue), name: command.name, type: command.type)),
                  },
                ),
              ),
              Expanded(
                child: DropdownButton<CommandName>(
                  value: command.name,
                  isExpanded: true,
                  onChanged: (CommandName? newName) {
                    if (newName != null) {
                      commandList.modifyCommand(index, Command(t: command.t, name: newName, type: command.type));
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
            ],
          ),
        );
      },
    );
  }
}
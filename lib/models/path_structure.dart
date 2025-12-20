import 'package:graveyard_shift_simulator/constants.dart';
import 'package:flutter/material.dart';
import 'dart:math';
//later add start and end speed to path model class
//also move commands into pathmodel
class Waypoint {
  Offset pos;
  Offset? handleIn;
  Offset? handleOut;
  double velocity;
  double accel;
  bool visible;
  bool reversed;

  Waypoint({
    required this.pos,
    this.handleIn,
    this.handleOut,
    this.velocity = maxVelocity,
    this.accel = 1,
    this.visible = true,
    this.reversed = false,
  });

  Map<String, dynamic> toJson() => {'x': pos.dx, 'y': pos.dy};
}

class Command {
  double t;
  int waypointIndex;
  CommandName name;

  Command({
    this.t = 0,
    required this.waypointIndex,
    this.name = CommandName.intake,
  });

  Map<String, dynamic> toJson() => {'t': t.toPrecision(4), 'name': name.name};
}

class LocalCommandT {
  final int waypointIndex;
  final double localT;

  LocalCommandT(this.waypointIndex, this.localT);
}


CommandName commandNameFromString(String s) {
  return CommandName.values.firstWhere(
    (e) => e.name == s,
    orElse: () => throw ArgumentError('Unknown command name: $s'),
  );
}


extension DoublePrecision on double {
  double toPrecision(int n) => double.parse(toStringAsFixed(n));
}

extension OffsetJson on Offset {
  Map<String, double> toJson() => {
    'x': (dx*0.0254).toPrecision(4),
    'y': (dy*0.0254).toPrecision(4),
  };
}

class Segment {
  final bool inverted;
  final bool stopEnd;
  final List<Offset> path;
  final double velocity;
  final double accel;

  Segment({
    required this.inverted,
    required this.stopEnd,
    required this.path,
    required this.velocity,
    required this.accel,
  });

  Map<String, dynamic> toJson() => {
    'inverted': inverted,
    'stop_end': stopEnd,
    'path': path.map((p) => p.toJson()).toList(),
    'constraints': {'velocity': velocity, 'accel': accel},
  };
}

class CommandList extends ChangeNotifier {
  final List<Command> commands = [];

  void addCommand(Command cmd) {
    commands.add(cmd);
    notifyListeners();
  }

  void changeCmdT(int i, double t) {
    commands[i].t = t;
    notifyListeners();
  }
  
  void removeCommand(int i) {
    commands.removeAt(i);
    notifyListeners();
  }

  void modifyCommand(int i, Command cmd) { //check for t
    commands[i] = cmd;
    notifyListeners();
  }
}

enum SegmentDragType { pos, handleIn, handleOut }
enum CommandName {intake, longgoal, uppercentergoal, matchloader}

class DragTargetInfo {
  final SegmentDragType type;
  final int index;
  DragTargetInfo({required this.type, required this.index});
}

class PathModel extends ChangeNotifier {
  List<Waypoint> waypoints = [];
  double startSpeed = 0.0;
  double endSpeed = 0.0;

  void addWaypoint(Waypoint wp) {
    waypoints.add(wp);
    notifyListeners();
  }

  void removeWaypoint(int i) {
    waypoints.removeAt(i);
    notifyListeners();
  }

  void updateWaypoint(int i, Waypoint wp) {
    waypoints[i] = wp;
    notifyListeners();
  }

  void setVisibility(int i, bool visible) {
    waypoints[i].visible = visible;
    notifyListeners();
  }

  void setReversed(int i, bool reversed) {
    waypoints[i].reversed = reversed;
    notifyListeners();
  }

  void setVelocity(int i, double velocity) {
    waypoints[i].velocity = velocity;
    notifyListeners();
  }

  void setAccel(int i, double accel) {
    waypoints[i].accel = accel;
    notifyListeners();
  }

  void clear() {
    waypoints.clear();
    notifyListeners();
  }

  void setPath(PathImportResult result) {
    waypoints = result.waypoints;
    startSpeed = result.startSpeed;
    endSpeed = result.endSpeed;
    notifyListeners();
  }
}
class PathImportResult {
  final List<Waypoint> waypoints;
  final List<Command> commands;
  final double startSpeed;
  final double endSpeed;

  PathImportResult({
    required this.waypoints,
    required this.commands,
    required this.startSpeed,
    required this.endSpeed,
  });
}
double distanceFormula(Offset prevPos, Offset pos) {
  final dist = sqrt(pow((pos.dy-prevPos.dy),2) + pow((pos.dx-prevPos.dx),2));
  return dist;
}

Offset computeHandleOffset(Offset prevPos, Offset pos, [double? setLength]) {
  final angle = atan2(pos.dy - prevPos.dy, pos.dx - prevPos.dx);
  final effectiveLength = setLength ?? distanceFormula(prevPos, pos);
  return Offset.fromDirection(angle, effectiveLength/2.0);
}

class VelocityPoint {
  double t;
  double v;

  VelocityPoint({required this.t, required this.v});
}

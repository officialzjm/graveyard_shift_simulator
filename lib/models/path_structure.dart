import 'package:flutter/material.dart';
import 'dart:math';

class Waypoint {
  Offset pos;
  Offset? handleIn;
  Offset? handleOut;
  bool visible;

  Waypoint({
    required this.pos,
    this.handleIn,
    this.handleOut,
    this.visible = true,
  });
}

class Command {
  double? t;
  CommandName? name;
  CommandType? type;

  Command({
    required this.t,
    required this.name,
    required this.type,
  });
}


class CommandList extends ChangeNotifier {
  final List<Command> commands = [];

  void addCommand(Command cmd) {
    commands.add(cmd);
    notifyListeners();
  }
  
  void modifyCommand(int i, Command cmd) { //check for t
    commands[i] = cmd;
    notifyListeners();
  }
}

enum SegmentDragType { pos, handleIn, handleOut }
enum CommandName {intake, longgoal, uppercentergoal, matchloader}
enum CommandType {enable, disable}

class DragTargetInfo {
  final SegmentDragType type;
  final int index;
  DragTargetInfo({required this.type, required this.index});
}

class PathModel extends ChangeNotifier {
  final List<Waypoint> waypoints = [];

  void addWaypoint(Waypoint wp) {
    waypoints.add(wp);
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

  void clear() {
    waypoints.clear();
    notifyListeners();
  }
  final List<VelocityPoint> velocityPoints = [
    VelocityPoint(t: 0.0, v: 0.0),
    VelocityPoint(t: 1.0, v: 0.0),
  ];

  void addVelocityPoint(VelocityPoint point) {
    velocityPoints.add(point);
    velocityPoints.sort((a, b) => a.t.compareTo(b.t));
    notifyListeners();
  }

  void updateVelocityPoint(int index, VelocityPoint point) {
    if (index >= 0 && index < velocityPoints.length) {
      velocityPoints[index] = point;
      velocityPoints.sort((a, b) => a.t.compareTo(b.t));
      notifyListeners();
    }
  }
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

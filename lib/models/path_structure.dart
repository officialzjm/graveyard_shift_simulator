import 'package:graveyard_shift_simulator/constants.dart';
import 'package:flutter/material.dart';
import 'package:graveyard_shift_simulator/segments.dart';
import 'package:vector_math/vector_math.dart';
import 'dart:math' as math;
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
    'x': (dx).toPrecision(4),
    'y': (dy).toPrecision(4),
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

  void setCommands(List<Command> cmds) {
    commands
      ..clear()
      ..addAll(cmds);
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
  List<BezierSegment> segments = [];
  double startSpeed = 0.0;
  double endSpeed = 0.0;
  List<double> times = [];
  List<double> pathTs = [];
  List<double> velocities = [];
  double duration = 0.0;
  
  double lerp(List<double> xs, List<double> ys, double x) {
        if (x <= xs[0]) return ys[0];
        if (x >= xs.last) return ys.last;
        for (int i = 1; i < xs.length; ++i) {
            if (xs[i] >= x) {
                double t = (x - xs[i-1]) / (xs[i] - xs[i-1]);
                return (1-t)*ys[i-1] + t*ys[i];
            }
        }
        return ys.last;
    }
  
  double limitSpeed(double k) {
      if (math.abs(k) < 1e-6) return 1.0;
      
      return 1.0 / (1.0 + math.abs(k * 0.5) * trackWidth);
  }
  
  void updateMotionProfile() {
    segments = [];
    for (int i=0; i<waypoints.length; i++) {
      segments.add(BezierSegment(waypoints[0].pos.toVector2(), waypoints[0].handleOut.toVector2(), waypoints[1].handleIn.toVector2(), waypoints[1].pos.toVector2(), waypoints[0].velocity, waypoints[0].accel, waypoints[0].reversed));
    }
    List<double> dist = [0.0];
    List<double> vels = [min(segments[0].curvature(0.0),maxVelocity)];
    List<double> accels = [0.0];
    pathTs.add(0.0);
    double totalDist = 0.0;
    
    for (int i = 0; i < segments.length - 1; ++i) { //-1?
        double length = segments[i].totalArcLength();
        int n = max(8, (length * 20.0).toInt());
        for (int j = 1; j <= n; ++j) {
            double t = j/n.toDouble();
            pathTs.add(i.toDouble() + t);
        
            dist.add(totalDist + segments[i].arcLengthAtT(t));
            double k = segments[i].curvature(t);
            vels.add(min(segments[i].maxVel, limitSpeed(k) * maxVelocity));
            accels.add(segments[i].maxAccel);
        }
        totalDist += length;
    }
    vels[vels.length - 1] = min(endSpeed, vels[vels.length - 1]);


    int n = dist.length;
    List<double> forwardPass = List<double>.filled(n, maxVelocity);    
    List<double> backwardPass = List<double>.filled(n, maxVelocity);

    forwardPass[0] = startSpeed;
    for (int i = 1; i < n; i++) {
        double deltaDist = dist[i] - dist[i-1];
        forwardPass[i] = min(maxVelocity,math.sqrt(math.pow(forwardPass[i-1], 2) + 2.0 * accels[i] * deltaDist));
    }

    backwardPass[n-1] = endSpeed;
    for (int i = n - 2; i >= 0; i--) {
        double deltaDist = dist[i+1] - dist[i];
        int segmentIndex = (pathTs[i].toInt());
        double a = segments[segmentIndex].maxAccel;
        backwardPass[i] = min(maxVelocity,math.sqrt(math.pow(backwardPass[i+1], 2) + 2.0 * accels[i] * deltaDist));
    }

    for (int i = 0; i < n; i++) {
        vels[i] = min(forwardPass[i], backwardPass[i]);
    }
    double time = 0.0;

    times.add(time);
    velocities.add(vels[0]);

    for (int i = 1; i < vels.length; i++) {
        double deltaDist = dist[i] - dist[i - 1];
        double deltaVel = pow(vels[i],2) - pow(vels[i - 1],2);
        double a = deltaVel / (2.0 * deltaDist);
        
        if (abs(a) > 0.1) {
            time += (vels[i] - vels[i - 1]) / a;
        } else {
            time += deltaDist / vels[i];
        }

        times.add(time);
        velocities.add(vels[i]);
    }
  }
  Waypoint getPointAtTime(double time) {
      double t = clamp(lerp(times, pathTs, time), 0.0, segments.length.toDouble());
      double i = clamp(t.toInt(), 0, segments.length - 1);
      double tLocal = fmod(t, 1.0000001);

      double desiredVelocity = lerp(times, velocities, time);
      Vector3 pose = segments[i].poseAtT(tLocal);
      return Waypoint(pos: {pose.x,pose.y}, velocity: desiredVelocity);
  }
  double getDuration() {
    return times[times.length-1];
  }
  void addWaypoint(Waypoint wp) {
    waypoints.add(wp);
    updateMotionProfile();
    notifyListeners();
  }

  void removeWaypoint(int i) {
    waypoints.removeAt(i);
    updateMotionProfile();
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
    updateMotionProfile();
    notifyListeners();
  }

  void setAccel(int i, double accel) {
    waypoints[i].accel = accel;
    updateMotionProfile();
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
  final angle = math.atan2(pos.dy - prevPos.dy, pos.dx - prevPos.dx);
  final effectiveLength = setLength ?? distanceFormula(prevPos, pos);
  return Offset.fromDirection(angle, effectiveLength/2.0);
}

class VelocityPoint {
  double t;
  double v;

  VelocityPoint({required this.t, required this.v});
}

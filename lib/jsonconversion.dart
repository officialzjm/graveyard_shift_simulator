import 'package:flutter/material.dart';
import 'package:graveyard_shift_simulator/models/path_structure.dart';
import 'package:graveyard_shift_simulator/bezierinfo.dart';
import 'dart:convert';
import 'dart:html' as html;



void downloadJsonWeb(String data, String filename) {
  final bytes = utf8.encode(data);

  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();

  html.Url.revokeObjectUrl(url);
}

String createPathJson(List<Waypoint> waypoints, List<Command> commands, [double startSpeed = 0.0, double endSpeed = 0.0]) {
  List<Segment> segments = createSegmentList(waypoints);
  final segmentLengths = computeSegmentLengths(waypoints);
  final cumulative = cumulativeDistances(segmentLengths);

  final exportedCommands = commands.map((cmd) {
    final globalTau = commandToGlobalT(
      cmd: cmd,
      waypoints: waypoints,
      segmentLengths: segmentLengths,
      cumulative: cumulative,
    );

    return {
      "t": globalTau.toPrecision(4),
      "name": cmd.name.name,
    };
  }).toList();

  Map<String, dynamic> root = {
    'start_speed': startSpeed,
    'end_speed': endSpeed,
    'segments': segments.map((s) => s.toJson()).toList(),
    'commands': exportedCommands,
  };

  return const JsonEncoder.withIndent('  ').convert(root);
}

List<Segment> createSegmentList(List<Waypoint> waypoints) {
  List<Segment> segments = [];
  for (int i = 0; i < waypoints.length-1; i++) {
    Waypoint wp = waypoints[i];
    Waypoint nextWp = waypoints[i+1];
    List<Offset> path = [];
    if (wp.handleOut != null && nextWp.handleIn != null) {
      path = [wp.pos,wp.handleOut!,nextWp.handleIn!,nextWp.pos];
    } else {
      path = [wp.pos,nextWp.pos];
    }
    segments.add(Segment(inverted: wp.reversed, stopEnd: false, path: path, velocity: (wp.velocity*0.0254).toPrecision(4), accel: (wp.accel*0.0254).toPrecision(4)));
  }
  return segments;
}

List<Command> importCommands(
  List<dynamic> jsonCommands,
  List<Waypoint> waypoints,
) {
  return jsonCommands.map((c) {
    final globalT = (c['t'] as num).toDouble();
    final localCmdT = globalTToLocalCommandT(globalT: globalT, waypoints: waypoints)
    return Command(
      name: commandNameFromString(c['name']),
      tau: localCmdT.localT,
      waypointIndex: localCmdT.waypointIndex,
    );
  }).toList();
}

import 'dart:math' as math;
// Preserve the lab's documented minimum Flutter SDK.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:steering_engine/steering_engine.dart';
import 'lab_theme.dart';

class SteeringPainter extends CustomPainter {
  SteeringPainter(
      {required this.agent,
      required this.target,
      required this.force,
      required this.trail,
      required this.showVectors,
      required this.showTrail,
      this.flock = const [],
      this.walls = const [],
      this.leader,
      this.queueLane = false,
      this.neighborhoodRadius,
      this.route,
      this.projection,
      this.avoidance,
      this.slowingRadius});
  final List<SteeringAgent> flock;
  final List<WallSegment> walls;
  final SteeringAgent? leader;
  final bool queueLane;
  final double? neighborhoodRadius;
  final SteeringPath? route;
  final PathProjection? projection;
  final ObstacleAvoidance? avoidance;
  final SteeringAgent agent;
  final Vec2 target;
  final Vec2 force;
  final List<Vec2> trail;
  final bool showVectors;
  final bool showTrail;
  final double? slowingRadius;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / worldSize.width, size.height / worldSize.height);
    final grid = Paint()
      ..color = const Color(0xff1e2c40)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= worldSize.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, worldSize.height), grid);
    }
    for (var y = 0.0; y <= worldSize.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(worldSize.width, y), grid);
    }
    Offset offset(Vec2 v) => Offset(v.x, v.y);
    for (final wall in walls) {
      canvas.drawLine(
          offset(wall.start),
          offset(wall.end),
          Paint()
            ..color = const Color(0xff91a8ff)
            ..strokeWidth = 4);
    }
    if (queueLane) {
      for (final y in [292.0, 328.0]) {
        canvas.drawLine(
            Offset(40, y),
            Offset(960, y),
            Paint()
              ..color = const Color(0xff42546d)
              ..strokeWidth = 1);
      }
    }
    if (leader != null) {
      canvas.save();
      canvas.translate(leader!.position.x, leader!.position.y);
      canvas.rotate(math.atan2(leader!.velocity.y, leader!.velocity.x));
      canvas.drawPath(
          Path()
            ..moveTo(18, 0)
            ..lineTo(-12, -10)
            ..lineTo(-12, 10)
            ..close(),
          Paint()..color = labGold);
      canvas.restore();
    }
    if (flock.isNotEmpty) {
      final radius = neighborhoodRadius!;
      final neighbors =
          AgentNeighborhood(flock).neighborsFor(agent, radius: radius).toSet();
      canvas.drawCircle(
          offset(agent.position),
          radius,
          Paint()
            ..color = labCyan.withValues(alpha: 0.12)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      for (final other in flock.skip(1)) {
        final color = neighbors.contains(other)
            ? const Color(0xffb2a4ff)
            : const Color(0xff5c8f95);
        if (showVectors) {
          _arrow(
              canvas,
              offset(other.position),
              offset(other.position + other.velocity * 0.2),
              color.withValues(alpha: 0.5));
        }
        canvas.save();
        canvas.translate(other.position.x, other.position.y);
        canvas.rotate(math.atan2(other.velocity.y, other.velocity.x));
        final body = Path()
          ..moveTo(10, 0)
          ..lineTo(-7, -5)
          ..lineTo(-4, 0)
          ..lineTo(-7, 5)
          ..close();
        canvas.drawPath(body, Paint()..color = color);
        canvas.restore();
      }
    }
    if (avoidance != null) {
      final behavior = avoidance!;
      final threat = behavior.findThreat(agent);
      for (final obstacle in behavior.obstacles) {
        final selected = identical(obstacle, threat?.obstacle);
        canvas.drawCircle(offset(obstacle.center), obstacle.radius,
            Paint()..color = Color(selected ? 0xffc66855 : 0xff66494c));
        canvas.drawCircle(
            offset(obstacle.center),
            obstacle.radius + behavior.agentRadius + behavior.safetyMargin,
            Paint()
              ..color = const Color(0xffe7a36a)
                  .withValues(alpha: selected ? 0.9 : 0.35)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      }
      canvas.drawCircle(
          offset(agent.position),
          behavior.agentRadius,
          Paint()
            ..color = labCyan.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke);
      if (agent.velocity.length > 0) {
        final end = agent.position +
            agent.velocity.normalized * behavior.scanDistance(agent);
        canvas.drawLine(
            offset(agent.position),
            offset(end),
            Paint()
              ..color = const Color(0xffe7a36a)
              ..strokeWidth = 1.5);
        if (threat != null && !threat.isOverlapping) {
          final entry =
              agent.position + agent.velocity.normalized * threat.entryDistance;
          canvas.drawCircle(
              offset(entry), 5, Paint()..color = const Color(0xffffd298));
        }
      }
    }
    if (projection != null) {
      final point = offset(projection!.point);
      canvas.drawLine(offset(agent.position), point,
          Paint()..color = const Color(0xff6ae4d4));
      canvas.drawCircle(point, 6, Paint()..color = const Color(0xff6ae4d4));
    }
    if (route != null) {
      final points = route!.waypoints;
      final path = Path()..moveTo(points.first.x, points.first.y);
      for (final point in points.skip(1)) {
        path.lineTo(point.x, point.y);
      }
      if (route!.loop) path.close();
      canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xffa497ff).withValues(alpha: 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      for (var i = 0; i < points.length; i++) {
        canvas.drawCircle(
            offset(points[i]), 5, Paint()..color = const Color(0xffa497ff));
        final label = TextPainter(
            text: TextSpan(
                text: '${i + 1}',
                style: const TextStyle(color: Color(0xffa497ff), fontSize: 14)),
            textDirection: TextDirection.ltr)
          ..layout();
        label.paint(canvas, offset(points[i]) + const Offset(9, -18));
      }
    }
    if (showTrail && trail.length > 1) {
      final path = Path()..moveTo(trail.first.x, trail.first.y);
      for (final point in trail.skip(1)) {
        path.lineTo(point.x, point.y);
      }
      canvas.drawPath(
          path,
          Paint()
            ..color = labCyan.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
    if (slowingRadius != null) {
      canvas.drawCircle(offset(target), slowingRadius!,
          Paint()..color = labGold.withValues(alpha: 0.05));
      canvas.drawCircle(
          offset(target),
          slowingRadius!,
          Paint()
            ..color = labGold.withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
    canvas.drawCircle(
        offset(target),
        13,
        Paint()
          ..color = labGold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawCircle(offset(target), 4, Paint()..color = labGold);
    final origin = offset(agent.position);
    if (showVectors) {
      _arrow(canvas, origin, offset(agent.position + agent.velocity * 0.65),
          labCyan);
      _arrow(canvas, origin, offset(agent.position + force * 0.35),
          const Color(0xffa497ff));
    }
    final heading = math.atan2(agent.velocity.y, agent.velocity.x);
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(heading);
    canvas.drawCircle(
        Offset.zero, 24, Paint()..color = labCyan.withValues(alpha: 0.08));
    final body = Path()
      ..moveTo(18, 0)
      ..lineTo(-12, -10)
      ..lineTo(-7, 0)
      ..lineTo(-12, 10)
      ..close();
    canvas.drawPath(body, Paint()..color = labCyan);
    canvas.restore();
    canvas.restore();
  }

  void _arrow(Canvas canvas, Offset from, Offset to, Color color) {
    if ((to - from).distance < 1) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5;
    canvas.drawLine(from, to, paint);
    final a = math.atan2(to.dy - from.dy, to.dx - from.dx);
    for (final side in [-1, 1]) {
      canvas.drawLine(
          to,
          to - Offset(math.cos(a + side * 0.5), math.sin(a + side * 0.5)) * 9,
          paint);
    }
  }

  @override
  bool shouldRepaint(SteeringPainter oldDelegate) => true;
}

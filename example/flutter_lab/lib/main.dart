import 'package:steering_lab_ui/steering_lab_ui.dart';
// Preserve Flutter 3.35 compatibility while newer SDKs re-export Material here.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'lab/lab_page.dart';
import 'lab/lab_theme.dart';
import 'lab/lab_modes.dart';

export 'lab/steering_painter.dart';

void main() => runApp(SteeringLab(initialMode: modeFromUri(Uri.base)));

class SteeringLab extends StatefulWidget {
  const SteeringLab({super.key, this.initialMode = 'Arrive'});

  final String initialMode;

  @override
  State<SteeringLab> createState() => _SteeringLabState();
}

class _SteeringLabState extends State<SteeringLab> {
  final _labKey = GlobalKey<LabPageState>();
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Steering Engine · Lab',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xff0b111c),
      colorScheme: ColorScheme.fromSeed(
        seedColor: labCyan,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    ),
    home: LabShell(
      onPreset: (mode) => _labKey.currentState?.selectMode(mode),
      laboratory: LabPage(key: _labKey, initialMode: widget.initialMode),
    ),
  );
}

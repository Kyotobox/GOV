import 'dart:io';
import 'package:antigravity_dpi/src/telemetry/telemetry_service.dart';

void main() async {
  final telemetry = TelemetryService();
  final pulse = await telemetry.computePulse(basePath: Directory.current.path);
  print('Turns: ${pulse.cpDetail['tools']}');
  print('CP: ${pulse.cp}');
  print('Saturation: ${pulse.saturation}%');
}

import 'package:antigravity_dpi/src/services/pulse_aggregator.dart';
import 'dart:io';

void main() async {
  final basePath = Directory.current.path;
  final aggregator = PulseAggregator(basePath);
  final pulse = await aggregator.calculatePulse();
  print('SHS: ${pulse.saturation}% | CUS: ${pulse.cp}%');
}

import 'dart:io';
import 'dart:convert';
import 'lib/src/services/fleet_service.dart';

void main() async {
  final fleet = FleetService(basePath: Directory.current.path);
  final states = await fleet.aggregateFleetPulse();
  print('Projects found: ${states.length}');
  for (var s in states) {
    print(' - ${s.name}: Online=${s.isOnline}, Path=${s.path}');
  }
}

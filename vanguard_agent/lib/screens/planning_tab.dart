import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/project.dart';

class PlanningTab extends StatelessWidget {
  final Project? project;
  const PlanningTab({super.key, this.project});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadPipeline(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final gates = snapshot.data!['gates'] ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(40),
          itemCount: gates.length,
          itemBuilder: (context, i) => Container(
            margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(16),
            color: Colors.white.withValues(alpha: 0.01),
            child: Row(children: [
               Icon(gates[i]['status'] == 'LOCKED' ? Icons.lock : Icons.radio_button_checked, color: Colors.cyanAccent.withValues(alpha: 0.3), size: 14),
               const SizedBox(width: 20),
               Text(gates[i]['id'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
               const Spacer(),
               Text(gates[i]['status'], style: const TextStyle(fontSize: 9, color: Colors.white24)),
            ]),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadPipeline() async {
    final file = File(p.join(project!.rootPath, '.meta', 'data', 'PIPELINE.json'));
    if (!await file.exists()) return {'gates': []};
    return jsonDecode(await file.readAsString());
  }
}

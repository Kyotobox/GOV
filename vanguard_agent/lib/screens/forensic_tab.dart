import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/project.dart';

class ForensicTab extends StatelessWidget {
  final Project? project;
  const ForensicTab({super.key, this.project});

  @override
  Widget build(BuildContext context) {
    if (project == null) return const Center(child: Text("ACCESO DENEGADO", style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w900, color: Colors.white10)));
    return FutureBuilder<List<dynamic>>(
      future: _loadHistory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 1));
        final history = snapshot.data!;
        
        if (history.isEmpty) return const Center(child: Text("LEGER VACÍO", style: TextStyle(color: Colors.white10, letterSpacing: 2)));

        return ListView.separated(
          itemCount: history.length, padding: const EdgeInsets.all(40),
          separatorBuilder: (context, i) => Divider(color: Colors.white.withValues(alpha: 0.03), height: 32),
          itemBuilder: (context, i) {
            final e = history[i];
            final bool isBase = e['type'] == 'BASE';
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isBase ? Colors.cyanAccent.withValues(alpha: 0.02) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (e['timestamp']?.toString().length ?? 0) >= 19 
                          ? e['timestamp'].toString().substring(11, 19) 
                          : (e['timestamp']?.toString().split('T').last ?? '??:??:??'),
                        style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 4),
                      Text(e['timestamp']?.toString().substring(0, 10) ?? '', style: const TextStyle(color: Colors.white10, fontSize: 7)),
                    ],
                  ),
                  const SizedBox(width: 30),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e['task'] ?? 'UNK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isBase ? Colors.cyanAccent : Colors.white70, letterSpacing: 0.5)),
                        if (e['detail'] != null) ...[
                          const SizedBox(height: 4),
                          Text(e['detail'], style: const TextStyle(color: Colors.white24, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(e['role'] ?? 'TECH', style: const TextStyle(color: Colors.cyanAccent, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
              ]),
            );
          },
        );
      },
    );
  }

  Future<List<dynamic>> _loadHistory() async {
    final file = File(p.join(project!.rootPath, 'vault', 'intel', 'signature_history.json'));
    if (!await file.exists()) return [];
    try {
      return jsonDecode(await file.readAsString());
    } catch (_) {
      return [];
    }
  }
}

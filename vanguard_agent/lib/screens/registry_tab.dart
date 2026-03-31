import 'package:flutter/material.dart';
import '../models/project.dart';

class RegistryTab extends StatelessWidget {
  final Project? project;
  final Map<String, dynamic>? backlog;
  const RegistryTab({super.key, this.project, this.backlog});

  String _getFriendlyName(String id) {
     if (backlog == null) return "Sin descripción.";
     final sprints = backlog!['sprints'] as List;
     for (var s in sprints) {
        final tasks = (s['tasks'] as List?) ?? [];
        for (var t in tasks) {
           if (t['id'] == id) return t['desc'] ?? t['title'] ?? id;
        }
     }
     return id;
  }

  @override
  Widget build(BuildContext context) {
    if (project == null || backlog == null) return const Center(child: Text("OFFLINE"));
    final sprints = backlog!['sprints'] as List;
    final active = sprints.firstWhere((s) => s['status'] == 'IN_PROGRESS', orElse: () => sprints.last);
    final tasks = active['tasks'] as List;

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Row(
        children: [
           _kanbanCol("PENDIENTES", tasks.where((t) => t['status'] == 'PENDING').toList(), Colors.white24),
           const SizedBox(width: 20),
           _kanbanCol("EJECUCIÓN", tasks.where((t) => t['status'] == 'IN_PROGRESS').toList(), Colors.cyanAccent),
           const SizedBox(width: 20),
           _kanbanCol("BLOQUEO", tasks.where((t) => t['status'] == 'WAITING' || t['status'] == 'LOCKED').toList(), Colors.amberAccent),
           const SizedBox(width: 20),
           _kanbanCol("TERMINADO", tasks.where((t) => t['status'] == 'DONE').toList(), Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _kanbanCol(String title, List tasks, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 20),
          Expanded(child: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, i) {
               final t = tasks[i];
               return TechnicalTaskCard(id: t['id'], name: _getFriendlyName(t['id']), color: color);
            },
          ))
        ],
      ),
    );
  }
}

class TechnicalTaskCard extends StatelessWidget {
  final String id;
  final String name;
  final Color color;
  const TechnicalTaskCard({super.key, required this.id, required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), border: Border.all(color: color.withValues(alpha: 0.1))),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(id.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          leading: const Icon(Icons.add_circle_outline, size: 14, color: Colors.white24),
          childrenPadding: const EdgeInsets.all(16),
          children: [
             Text(name, style: const TextStyle(color: Colors.white70, fontSize: 10, height: 1.5, fontStyle: FontStyle.italic)),
             const SizedBox(height: 12),
             Row(children: [
               const Icon(Icons.verified_user, size: 10, color: Colors.white24),
               const SizedBox(width: 8),
               Text("ESTADO: $id", style: const TextStyle(fontSize: 8, color: Colors.white10)),
             ])
          ],
        ),
      ),
    );
  }
}

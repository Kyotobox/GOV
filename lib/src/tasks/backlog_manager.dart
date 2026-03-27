import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

/// BacklogManager: Manages backlog.json and synchronizes with task.md.
class BacklogManager {
  /// Loads and validates the backlog.json file.
  Future<Map<String, dynamic>> loadBacklog({required String basePath}) async {
    final backlogFile = File(p.join(basePath, 'backlog.json'));
    if (!await backlogFile.exists()) {
      throw Exception('backlog.json not found.');
    }
    final content = await backlogFile.readAsString();
    return jsonDecode(content);
  }

  /// Synchronizes the task.md based on the active sprint.
  Future<void> syncTaskMd({required Map<String, dynamic> backlog, required String basePath}) async {
    final taskMdFile = File(p.join(basePath, 'task.md'));
    
    // Find IN_PROGRESS sprint
    final sprints = backlog['sprints'] as List;
    final activeSprint = sprints.firstWhere(
      (s) => s['status'] == 'IN_PROGRESS' || s['status'] == 'IN-PROGRESS',
      orElse: () => null,
    );

    if (activeSprint == null) return;

    final buffer = StringBuffer();
    buffer.writeln('# SPRINT ${activeSprint['id']} - ${activeSprint['name']}');
    buffer.writeln('**Objetivo**: ${activeSprint['goal']}');
    buffer.writeln('**Fecha**: ${DateTime.now().toIso8601String().split('T')[0]}');
    buffer.writeln('');

    final tasks = activeSprint['tasks'] as List;
    for (var task in tasks) {
      final status = task['status'] == 'DONE' ? '[x]' : (task['status'] == 'IN_PROGRESS' ? '[/]' : '[ ]');
      buffer.writeln('- $status **${task['id']}** [${task['label']}] ${task['desc']}');
    }

    await taskMdFile.writeAsString(buffer.toString());
  }

  /// Returns the currently active sprint from the backlog.
  Future<Map<String, dynamic>?> getActiveSprint({required Map<String, dynamic> backlog}) async {
    final sprints = backlog['sprints'] as List?;
    if (sprints == null) return null;
    
    final active = sprints.firstWhere(
      (s) => s['status'] == 'IN_PROGRESS' || s['status'] == 'IN-PROGRESS',
      orElse: () => null,
    );
    
    return active != null ? Map<String, dynamic>.from(active) : null;
  }

  /// returns tasks that are NOT 'DONE'.
  List<Map<String, dynamic>> getPendingTasks(Map<String, dynamic> sprint) {
    final tasks = sprint['tasks'] as List?;
    if (tasks == null) return [];
    
    return tasks
        .where((t) => t['status'] != 'DONE' && t['status'] != 'COMPLETED')
        .map((t) => Map<String, dynamic>.from(t))
        .toList();
  }

  /// returns the first task that is 'IN_PROGRESS' or 'PENDING'.
  Map<String, dynamic>? getActiveTask(Map<String, dynamic> sprint) {
    final tasks = sprint['tasks'] as List?;
    if (tasks == null) return null;
    
    final active = tasks.firstWhere(
      (t) => t['status'] == 'IN_PROGRESS' || t['status'] == 'IN-PROGRESS',
      orElse: () => tasks.firstWhere((t) => t['status'] == 'PENDING', orElse: () => null),
    );
    
    return active != null ? Map<String, dynamic>.from(active) : null;
  }

  /// Checks if any task in task.md is currently being executed by another instance.
  /// Returns a list of tasks that are 'IN_PROGRESS' [/].
  Future<List<String>> checkConcurrency({required String basePath}) async {
    final taskMdFile = File(p.join(basePath, 'task.md'));
    if (!await taskMdFile.exists()) return [];

    final lines = await taskMdFile.readAsLines();
    final inProgressTasks = <String>[];
    for (final line in lines) {
      if (line.contains('[ / ]') || line.contains('[/]')) {
        // Extract Task ID (e.g. TASK-DPI-S05-03 or TASK-101H-05)
        final match = RegExp(r'\*\*(TASK-[A-Z0-9-]*)\*\*').firstMatch(line);
        if (match != null) {
          inProgressTasks.add(match.group(1)!);
        }
      }
    }
    return inProgressTasks;
  }
}

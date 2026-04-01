import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/project.dart';

class TerminalTab extends StatelessWidget {
  final String? challenge;
  final String? level;
  final String? description;
  final Project? project;
  final Color accent;
  final double saturation;
  final double cus; // [S25-03] NUEVO
  final double bhi; // [S25-03] NUEVO
  final bool isGov;
  final String version; // [NEW] 
  final List<dynamic> history;
  final VoidCallback onViewHistory;
  final int timeRemaining;
  final String activeTaskId;
  final int debts;
  final int turns;
  final String lastPushDate; // [S25-08]
  final bool pushIsStale;    // [S25-08]
  final VoidCallback onChallengeCleared;

  const TerminalTab({
    super.key,
    this.challenge, 
    this.level, 
    this.description, 
    this.project, 
    required this.accent, 
    required this.saturation, 
    required this.cus, // [S25-03]
    required this.bhi, // [S25-03]
    required this.isGov,
    required this.version, // [NEW]
    required this.history,
    required this.onViewHistory,
    required this.timeRemaining,
    required this.activeTaskId,
    required this.debts,
    required this.turns,
    required this.lastPushDate, // [S25-08]
    required this.pushIsStale,   // [S25-08]
    required this.onChallengeCleared,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (!isGov) Center(child: DualGaugePanel(bhi: bhi, cus: cus, accent: accent, activeTaskId: activeTaskId)),
        if (isGov) Center(child: Opacity(opacity: 0.05, child: Icon(Icons.security, size: 400, color: accent))),
        
        if (challenge != null) Positioned(
          bottom: 40, right: 40,
          child: SignatureGuardButton(challenge: challenge, level: level, description: description, project: project, accent: accent, onComplete: onChallengeCleared),
        ),

        Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               if (!isGov) _buildTelemetryPanel(),
               const Spacer(),
                if (challenge != null) _buildActiveChallengePanel(),
                if (challenge == null) _buildIdlePanel(),
                const SizedBox(height: 40),
                if (!isGov) _buildHistoryMiniPanel(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryMiniPanel() {
    return Container(
      width: 450,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.02),
        border: Border.all(color: accent.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("ÚLTIMOS SELLOS DE CALIDAD", style: TextStyle(fontSize: 8, color: Colors.white24, letterSpacing: 2)),
              InkWell(
                onTap: onViewHistory,
                child: Text("VER EXTENDIDO >", style: TextStyle(fontSize: 8, color: accent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (history.isEmpty) const Text("SIN REGISTROS", style: TextStyle(fontSize: 10, color: Colors.white10)),
          ...history.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  (e['timestamp']?.toString().length ?? 0) >= 19 
                    ? e['timestamp'].toString().substring(11, 19) 
                    : (e['timestamp']?.toString().split('T').last ?? '??:??:??'), 
                  style: const TextStyle(fontSize: 9, color: Colors.white24)
                ),
                const SizedBox(width: 15),
                Expanded(child: Text(e['detail']?.toString().toUpperCase() ?? e['task'].toString().toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                Text(e['role'], style: TextStyle(fontSize: 9, color: accent.withValues(alpha: 0.5))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTelemetryPanel() {
    return Container(
      width: 280, padding: const EdgeInsets.all(20),
      color: Colors.black12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ESTADO DE NÚCLEO", style: TextStyle(fontSize: 9, color: Colors.white38, letterSpacing: 2)),
          const SizedBox(height: 15),
          Tooltip(
            message: "Nivel de saturación cognitiva (SHS). Representa la carga acumulada del modelo.\nDominancia Dinámica: Toma el valor más alto entre el uso real y la seguridad forzada.",
            child: _kvLine("PUNTO DE SALUD", "${(saturation * 100).toInt()}%")
          ),
          _kvLine("ESTADO BÚNKER", "SEGURIZADO"),
          _kvLine("VERSIÓN KERNEL", version, color: accent), // [NEW]
          _kvLine("ROOT_PROJECT", project?.id.toUpperCase() ?? "NONE"),
          const Divider(color: Colors.white10),
          Tooltip(
            message: "Tareas pendientes con etiqueta DEBT o hito fallido. Afectan la resiliencia del sprint.",
            child: _kvLine("DEUDA PENDIENTE", "$debts TAREAS")
          ),
          Tooltip(
            message: "Número de interacciones atómicas (tool calls) registradas en esta sesión.",
            child: _kvLine("ACCIONES (TURNOS)", "$turns OPS")
          ),
          const Divider(color: Colors.white10),
          Tooltip(
            message: 'Fecha y hora del último commit pusheado al repositorio remoto.\nSi es > 24h, considera hacer push para sincronizar el Motor.',
            child: _kvLine(
              'ÚLTIMO PUSH', 
              lastPushDate, 
              color: pushIsStale ? Colors.orangeAccent : null
            ),
          ),
        ],
      ),
    );
  }

  Widget _kvLine(String k, String v, {bool small = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: TextStyle(fontSize: small ? 7 : 8, color: Colors.white24)),
          Text(v, style: TextStyle(
            fontSize: small ? 9 : 10, 
            fontWeight: FontWeight.bold, 
            color: color ?? accent
          )),
        ],
      ),
    );
  }

  Widget _buildActiveChallengePanel() {
     return Container(
      width: 450, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(level?.toUpperCase() ?? "SIN NIVEL", style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              if (level != null) Icon(Icons.warning_amber_rounded, color: accent, size: 14),
            ],
          ),
          const SizedBox(height: 12),
          _kvLine("TIEMPO RESTANTE", "${timeRemaining}s", small: true),
          const SizedBox(height: 12),
          Text(challenge!, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -1)),
          const SizedBox(height: 24),
          NukeButton(project: project, accent: accent, onComplete: onChallengeCleared),
        ],
      ),
    );
  }

  Widget _buildIdlePanel() {
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("MONITOR OPERATIVO", style: TextStyle(fontSize: 9, color: Colors.white24, letterSpacing: 2)),
        const SizedBox(height: 5),
        Text(isGov ? "NODOS DE GOBERNANZA PASIVOS" : "SISTEMA SEGURO — ESPERANDO SOLICITUDES", style: const TextStyle(fontSize: 10, color: Colors.white24)),
      ],
    );
  }
}

class DualGaugePanel extends StatelessWidget {
  final double bhi;
  final double cus;
  final Color accent;
  final String activeTaskId;

  const DualGaugePanel({
    super.key,
    required this.bhi,
    required this.cus,
    required this.accent,
    required this.activeTaskId,
  });

  Color _colorFor(double value, {required bool isBhi}) {
    if (value < 0.5) return isBhi ? Colors.greenAccent : Colors.cyanAccent;
    if (value < 0.75) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGauge('BHI', 'BÚNKER', bhi, _colorFor(bhi, isBhi: true)),
            const SizedBox(width: 48),
            _buildGauge('CUS', 'CONTEXTO', cus, _colorFor(cus, isBhi: false)),
          ],
        ),
        const SizedBox(height: 16),
        Tooltip(
          message: 'ID de la tarea activa en el backlog de gobernanza.',
          child: Text(
            activeTaskId,
            style: TextStyle(
              color: accent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGauge(String label, String subtitle, double value, Color color) {
    return Tooltip(
      message: label == 'BHI'
          ? 'Bunker Health Index: Salud estructural del búnker.\nSube con zombies y deuda técnica. Se reduce con housekeeping.'
          : 'Context Utilization Score: Fatiga cognitiva del modelo.\nSube con cada act/baseline. Se resetea con handover.',
      child: SizedBox(
        width: 140, height: 140,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(140, 140),
              painter: _ArcGaugePainter(value: value, color: color),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 9, letterSpacing: 3)),
                const SizedBox(height: 4),
                Text('${(value * 100).toInt()}%', style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -2)),
                Text(subtitle, style: TextStyle(color: color.withValues(alpha: 0.3), fontSize: 7, letterSpacing: 1.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  final double value;
  final Color color;
  const _ArcGaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const startAngle = 2.36; // -135 degrees
    const sweepMax = 4.71;   // 270 degrees
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    // Background arc
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepMax, false, bgPaint);
    // Foreground arc (filled)
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepMax * value.clamp(0.0, 1.0), false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class SignatureGuardButton extends StatefulWidget {
  final String? challenge;
  final String? level;
  final String? description;
  final Project? project;
  final Color accent;
  final VoidCallback onComplete;
  const SignatureGuardButton({super.key, this.challenge, this.level, this.description, this.project, required this.accent, required this.onComplete});

  @override
  State<SignatureGuardButton> createState() => _SignatureGuardButtonState();
}

class _SignatureGuardButtonState extends State<SignatureGuardButton> {
  bool _signing = false;
  double _bioProgress = 0.0;
  Timer? _timer;

  bool get _isCritical => ['CRITICAL', 'SECURITY', 'ADMIN', 'KERNEL-CORE', 'INTERNAL-PROMPT'].contains(widget.level?.toUpperCase());

  Future<void> _execute() async {
    if (widget.challenge == null || widget.project == null) return;
    setState(() => _signing = true);
    if (_isCritical) {
       final random = math.Random().nextBool();
       if (random) await Future.delayed(const Duration(milliseconds: 400));
    }
    final scriptPath = p.join(widget.project!.rootPath, 'scripts', 'sign_challenge.ps1');
    try {
      final result = await Process.run('powershell', ['-ExecutionPolicy', 'Bypass', '-File', scriptPath, '-Challenge', widget.challenge!, '-KeyPath', widget.project!.keyPath], workingDirectory: widget.project!.rootPath);
      if (result.exitCode != 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Firma fallida: ${result.stderr}'), backgroundColor: Colors.redAccent));
      } else if (result.exitCode == 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Certificado OK. Hito consolidado.'), backgroundColor: Colors.green, duration: Duration(seconds: 2)));
        widget.onComplete(); // Notifies Parent to clear challenge
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de sistema: $e'), backgroundColor: Colors.redAccent));
    }
    if (mounted) setState(() { _signing = false; _bioProgress = 0.0; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCritical) {
      return GestureDetector(
        onLongPressStart: (_) => _timer = Timer.periodic(const Duration(milliseconds: 20), (t) => setState(() { _bioProgress += 0.02; if (_bioProgress >= 1.0) { t.cancel(); _execute(); } })),
        onLongPressEnd: (_) { _timer?.cancel(); if (_bioProgress < 1.0) setState(() => _bioProgress = 0.0); },
        child: Container(
          width: 280, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: _bioProgress * 0.3), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: _bioProgress, minHeight: 4, color: widget.accent)),
               const SizedBox(height: 12),
               Text(widget.description ?? "SIN DETALLES", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
               const SizedBox(height: 12),
               Text("AUTORIZAR HITO (CLICK)", style: TextStyle(color: widget.accent, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }
    return InkWell(
      onTap: _signing ? null : _execute,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        decoration: BoxDecoration(color: widget.accent, boxShadow: [BoxShadow(color: widget.accent.withValues(alpha: 0.3), blurRadius: 20)]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_signing) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
            else const Icon(Icons.fingerprint, color: Colors.black, size: 20),
            const SizedBox(width: 16),
            Text(_signing ? "FIRMANDO..." : "CERTIFICAR (CLICK)", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class NukeButton extends StatelessWidget {
  final Project? project;
  final Color accent;
  final VoidCallback onComplete;
  const NukeButton({super.key, this.project, required this.accent, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        if (project == null) return;
        final cFile = File(p.join(project!.rootPath, 'vault', 'intel', 'challenge.json'));
          if (await cFile.exists()) {
            await cFile.delete();
            onComplete();
          }
      },
      icon: const Icon(Icons.close, size: 14, color: Colors.redAccent),
      label: const Text("RECHAZAR / NUKE", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';
import 'dart:ui';

import 'models/project.dart';
import 'screens/terminal_tab.dart';
import 'screens/registry_tab.dart';
import 'screens/planning_tab.dart';
import 'screens/forensic_tab.dart';
import 'features/dpi_init/dpi_init_wizard_screen.dart';
import 'features/dpi_adopt/dpi_adopt_wizard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VanguardElite());
}

/// [DPI-VANGUARD-6.6] — Pulse Intelligence & Stealth
class VanguardElite extends StatelessWidget {
  const VanguardElite({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vanguard Elite 8.0.0',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'monospace',
        colorSchemeSeed: Colors.cyanAccent,
        scaffoldBackgroundColor: const Color(0xFF000508),
      ),
      home: const MainHUD(),
    );
  }
}

// --- [HUD MAIN CONTROLLER] ---

class MainHUD extends StatefulWidget {
  const MainHUD({super.key});

  @override
  State<MainHUD> createState() => _MainHUDState();
}

class _MainHUDState extends State<MainHUD> with TickerProviderStateMixin {
  int _navIndex = 0;
  List<Project> _projects = [];
  Project? _selectedProject;
  
  // Health Metrics (V8.0 Dual-Motor)
  double _cus = 0.0;
  double _bhi = 0.0;
  double _saturation = 0.0;
  bool _isSealed = false; // [S25-04] Estado post-handover
  String? _lastSeenChallengeId;
  int _zombies = 0;
  String _sprintId = 'WAITING';
  String _activeTaskId = '---';
  String _activeProjectVersion = 'v8.0.0'; // [S25-07] Versión dinámica
  String _lastPushDate = '---';  // [S25-08]
  bool _pushIsStale = false;     // [S25-08]
  bool _driftAlert = false;
  int _debts = 0;
  int _turns = 0;
  DateTime _sessionStart = DateTime.now(); // Cold time reference
  DateTime? _takeoverTime;
  DateTime? _lastActionTs;
  String _sessionUuid = '---';
  final Set<String> _handledChallenges = {};
  
  // Tactical Actions
  bool _confirmingHandover = false;
  Timer? _heartbeat;
  
  // Challenge State
  String? _challenge;
  String? _level;
  String? _description;
  Map<String, dynamic>? _backlog;
  List<dynamic> _recentHistory = [];
  int _timeRemaining = 0;
  Timer? _countdownTimer;

  // Pulse & BlackGate
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  StreamSubscription? _subscription;
  late AnimationController _glowController;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _pulseAnimation = Tween<double>(begin: 0.0, end: 0.15).animate(_pulseController);
    
    // [TASK-119-06] Heartbeat Sync Engine (15s Loop)
    _heartbeat = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_selectedProject != null) _runPulse();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _heartbeat?.cancel();
    _countdownTimer?.cancel();
    _glowController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // [S25-07] Resolver ruta del Oráculo desde el ejecutable
  String _resolveOracleRoot() {
    final exePath = Platform.resolvedExecutable;
    final exeDir = Directory(p.dirname(exePath));
    // Si Vanguard.exe es dev/build o está en bin/
    if (p.basename(exeDir.path) == 'bin' || p.basename(exeDir.path) == 'debug' || p.basename(exeDir.path) == 'release') {
      return exeDir.parent.path;
    }
    return exeDir.path;
  }

  Future<void> _loadSettings() async {
    final oracleRoot = _resolveOracleRoot();
    final masterFleetPath = p.join(oracleRoot, 'vault', 'intel', 'fleet_registry.json');
    
    try {
      final fleetFile = File(masterFleetPath);
      if (await fleetFile.exists()) {
        final data = jsonDecode(await fleetFile.readAsString());
        final List<dynamic> bunkers = data['bunkers'] ?? data['projects'] ?? [];
        _projects = bunkers.map((e) {
          final bunker = Project.fromJson(e);
          return Project(
            id: bunker.id,
            name: bunker.name,
            rootPath: bunker.rootPath,
            keyPath: bunker.rootPath.contains('Base2') 
              ? p.join(bunker.rootPath, 'vault', 'intel', 'signature_history.json')
              : 'root',
          );
        }).toList();
        
        // Agregar el Oráculo dinámicamente si no está
        if (!_projects.any((p) => p.isGovMode)) {
          _projects.add(Project(id: 'gov', name: 'KYOTOBOX - GOV', rootPath: oracleRoot, keyPath: 'root'));
        }
      } else {
        // Fallback sin hardcoding
        _projects = [
          Project(id: 'gov', name: 'KYOTOBOX - GOV', rootPath: oracleRoot, keyPath: 'root')
        ];
      }
    } catch (e) {
      debugPrint('[VANGUARD-FLEET] Load error: $e');
      _projects = [
        Project(id: 'gov', name: 'KYOTOBOX - GOV', rootPath: oracleRoot, keyPath: 'root')
      ];
    }

    if (mounted && _projects.isNotEmpty) _selectProject(_projects.first);
  }

  void _selectProject(Project project) {
    _subscription?.cancel();
    setState(() {
      _selectedProject = project;
      _challenge = null;
      _isSealed = false; // [S25-04] Resetear estado SEALED
      _handledChallenges.clear(); 
      if (project.isGovMode) _navIndex = 0;
    });
    _startWatcher(project);
    _refreshTelemetry(project);
    _loadSessionTimer(project);
  }

  Future<void> _loadSessionTimer(Project project) async {
    final lockFile = File(p.join(project.rootPath, '.meta', 'SESSION_LOCKED'));
    if (await lockFile.exists()) {
      final ts = await lockFile.lastModified();
      setState(() => _sessionStart = ts);
    } else {
      setState(() => _sessionStart = DateTime.now());
    }

    // [TASK-DPI-126-11] Load Active Session Takeover Time
    final sessionLock = File(p.join(project.rootPath, '.meta', 'session.lock'));
    if (await sessionLock.exists()) {
      try {
        final data = jsonDecode(await sessionLock.readAsString());
        if (data['timestamp'] != null) {
          setState(() {
            _takeoverTime = DateTime.parse(data['timestamp']);
            _sessionUuid = data['chat_uuid'] ?? 'UNKNOWN';
          });
        }
      } catch (_) {}
    } else {
       setState(() {
         _takeoverTime = null;
         _sessionUuid = 'UNLOCKED';
       });
    }
  }

  void _startWatcher(Project project) {
    final intelDir = p.join(project.rootPath, 'vault', 'intel');
    if (!Directory(intelDir).existsSync()) return;
    final watcher = DirectoryWatcher(intelDir);
    _subscription = watcher.events.listen((event) {
      if (event.path.endsWith('challenge.json') || event.path.endsWith('intel_pulse.json') || event.path.endsWith('backlog.json')) {
        _refreshTelemetry(project);
      }
    });
  }

  Future<void> _refreshTelemetry(Project project) async {
    final String? oldChallenge = _challenge;
    final double lastSaturation = _saturation;
    final bool lastDrift = _driftAlert;

    // 1. Challenge
    final cFile = File(p.join(project.rootPath, 'vault', 'intel', 'challenge.json'));
    if (await cFile.exists()) {
      try {
        final data = jsonDecode(await cFile.readAsString());
        final String newId = data['challenge'];
        
        // [FIX-UX] Evitar re-mostrar desafíos ya procesados localmente
        if (!_handledChallenges.contains(newId)) {
          if (mounted) {
            setState(() {
              _challenge = newId;
              _level = data['level'];
              _description = data['description'];
            });
          }
        } else {
          if (mounted) setState(() => _challenge = null);
        }
      } catch (_) {}
    } else { 
      if (mounted) setState(() => _challenge = null); 
    }

    // 1b. Timeout Check
    _countdownTimer?.cancel();
    if (_challenge != null) {
      final tsStr = (jsonDecode(await cFile.readAsString()))['timestamp'];
      if (tsStr != null) {
        final ts = DateTime.parse(tsStr);
        final diff = DateTime.now().difference(ts).inSeconds;
        if (diff > 60) {
          if (mounted) setState(() { _challenge = null; _timeRemaining = 0; });
        } else {
          setState(() => _timeRemaining = 60 - diff);
          _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
            if (_timeRemaining > 0) {
              setState(() => _timeRemaining--);
            } else {
              t.cancel();
              if (mounted) setState(() => _challenge = null);
            }
          });
        }
      }
    }

    // 2. SHS Pulse
    final pFile = File(p.join(project.rootPath, 'vault', 'intel', 'intel_pulse.json'));
    if (await pFile.exists()) {
      try {
        final data = jsonDecode(await pFile.readAsString());
        if (mounted) {
          setState(() {
            _cus = (data['cp_fatigue'] ?? data['cp'] ?? 0.0) / 100.0;
            _bhi = (data['bhi'] ?? data['hygiene']?['bhi'] ?? 0.0) / 100.0;
            _saturation = (data['saturation'] ?? 0.0) / 100.0;
            _zombies = (data['zombies'] ?? 0);
            _driftAlert = data['drift_alert'] ?? false;
            _turns = data['cp_detail']?['tools']?.toInt() ?? 0;
            _sessionUuid = data['session_uuid'] ?? _sessionUuid;
            if (data['cp_detail']?['last_action_ts'] != null) {
              _lastActionTs = DateTime.parse(data['cp_detail']['last_action_ts']);
            }
            if (data['start_timestamp'] != null) {
              _takeoverTime = DateTime.parse(data['start_timestamp']);
            }
            
            // [TASK-125-02] Event-Based Alarms
            final bool isNewChallenge = _challenge != null && _challenge != _lastSeenChallengeId;
            final bool isCriticalHit = _saturation >= 0.90 && lastSaturation < 0.90;

            if (isNewChallenge || isCriticalHit) {
               SystemSound.play(SystemSoundType.alert);
               _shimmerController.forward(from: 0.0);
               _lastSeenChallengeId = _challenge;
            }

            if (_saturation >= 0.90 || (_challenge != null && (_level?.toUpperCase().contains('BLACK') ?? false))) {
              _pulseController.repeat(reverse: true);
            } else {
              _pulseController.stop();
              _pulseController.value = 0;
            }
          });
        }
      } catch (_) {}
    }

    // 3. Backlog
    final bFile = File(p.join(project.rootPath, 'backlog.json'));
    if (await bFile.exists()) {
      try {
        final data = jsonDecode(await bFile.readAsString());
        if (mounted) {
          setState(() {
            _backlog = data;
            final sprints = (data['sprints'] as List?) ?? [];
            if (sprints.isNotEmpty) {
              final active = sprints.firstWhere((s) => s['status'] == 'IN_PROGRESS', orElse: () => null);
              if (active != null) {
                _sprintId = active['id'];
                final tasks = (active['tasks'] as List?) ?? [];
                final running = tasks.firstWhere((t) => t['status'] == 'IN_PROGRESS', orElse: () => null);
                _activeTaskId = running != null ? running['id'] : '---';
              }
            }

            // [S25-07] Leer versión del backlog
            final version = data['version'] ?? data['kernel_version'] ?? 'v8.0.0';
            _activeProjectVersion = version;
            
            // [S120] Calcular Deuda Pendiente
            _debts = 0;
            for (var sprint in sprints) {
              final tasks = sprint['tasks'] as List? ?? [];
              _debts += tasks.where((t) => (t['label'] == 'DEBT' || t['id'].contains('DEBT')) && t['status'] != 'DONE').length;
            }
          });
        }
      } catch (_) {}
    }

    // 4. History
    final hFile = File(p.join(project.rootPath, 'vault', 'intel', 'signature_history.json'));
    if (await hFile.exists()) {
      try {
        final List<dynamic> history = jsonDecode(await hFile.readAsString());
        if (mounted) setState(() => _recentHistory = history.take(5).toList());
      } catch (_) {}
    }
  }

  // --- [TACTICAL ACTIONS] ---

  String _getGovPath(String root) {
    final binPath = p.join(root, 'bin', 'gov.exe');
    if (File(binPath).existsSync()) return binPath;
    return p.join(root, 'gov.exe');
  }

  Future<void> _runPulse() async {
    final root = _selectedProject?.rootPath;
    if (root == null) return;
    try {
      final result = await Process.run(_getGovPath(root), ['pulse'], workingDirectory: root);
      if (result.exitCode == 0) {
        await _refreshTelemetry(_selectedProject!);
        _loadLastPushDate(root); // [S25-08] Actualizar push date en cada pulso
      }
    } catch (e) {
      debugPrint('[VANGUARD-HEARTBEAT] Kernel unreachable: $e');
    }
  }

  // [S25-08] Obtener fecha del último push remoto
  Future<void> _loadLastPushDate(String rootPath) async {
    try {
      final result = await Process.run(
        'git',
        ['log', '--remotes', '-1', '--format=%ai'],
        workingDirectory: rootPath,
        runInShell: true,
      );
      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        final rawDate = result.stdout.toString().trim();
        // 2026-03-30 06:37:15 -0400 -> 2026-03-30T06:37:15
        final parts = rawDate.split(' ');
        if (parts.length >= 2) {
          final dt = DateTime.parse('${parts[0]}T${parts[1]}');
          final diff = DateTime.now().difference(dt);
          final String formatted = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          if (mounted) {
            setState(() {
              _lastPushDate = formatted;
              _pushIsStale = diff.inHours > 24;
            });
          }
        }
      } else {
        if (mounted) setState(() => _lastPushDate = 'SIN REMOTE');
      }
    } catch (_) {
      if (mounted) setState(() => _lastPushDate = 'NO GIT');
    }
  }

  Future<void> _runPurge() async {
    final root = _selectedProject?.rootPath;
    if (root == null) return;
    try {
      await Process.run(_getGovPath(root), ['housekeeping'], workingDirectory: root);
      _refreshTelemetry(_selectedProject!);
    } catch (_) {}
  }

  Future<void> _runHandover() async {
    final root = _selectedProject?.rootPath;
    if (root == null) return;
    try {
      await Process.run(_getGovPath(root), ['handover'], workingDirectory: root);
      if (mounted) setState(() {
        _confirmingHandover = false;
        _isSealed = true; // [S25-04]
      });
      _refreshTelemetry(_selectedProject!);
    } catch (_) {}
  }

  Future<void> _runForcedHandover() async {
    final root = _selectedProject?.rootPath;
    if (root == null) return;
    if (mounted) setState(() => _confirmingHandover = false);
    try {
      await Process.run(_getGovPath(root), ['handover', '--force'], workingDirectory: root);
      if (mounted) setState(() => _isSealed = true); // [S25-04]
      _refreshTelemetry(_selectedProject!);
    } catch (_) {}
  }

  Future<void> _runBaseline() async {
    final root = _selectedProject?.rootPath;
    if (root == null) return;
    try {
      await Process.run(_getGovPath(root), ['baseline', 'HUD Update'], workingDirectory: root);
      _refreshTelemetry(_selectedProject!);
    } catch (_) {}
  }


  @override
  Widget build(BuildContext context) {
    final bool isGov = _selectedProject?.isGovMode ?? false;
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final Color themeColor = _challenge == null ? Colors.cyanAccent : _getThemeColor(_level ?? "");
        final Color accent = Color.lerp(themeColor, Colors.redAccent, isGov ? 0.0 : _saturation)!;
        final Color bgColor = _challenge == null ? const Color(0xFF000508) : themeColor.withValues(alpha: 0.1);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF000508),
              gradient: _challenge != null ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [bgColor, const Color(0xFF000508)]) : null,
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    if (!isGov) _buildSidebar(accent),
                    Expanded(
                      child: Column(
                        children: [
                          _buildHeader(themeColor, accent, isGov),
                          Expanded(child: _buildCurrentTab(accent, isGov)),
                        ],
                      ),
                    ),
                  ],
                ),
                // [TASK-119-06] BlackGate Critical Pulse Overlay
                if (_saturation >= 0.90 || (_challenge != null && (_level?.toUpperCase().contains('BLACK') ?? false))) 
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, _) => Container(color: Colors.red.withValues(alpha: _pulseAnimation.value)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebar(Color color) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 80,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: color.withValues(alpha: 0.15))),
            color: Colors.black.withValues(alpha: 0.7),
          ),
          child: Column(
            children: [
              const SizedBox(height: 32),
              _buildNavIcon(0, Icons.radar, "OPERACIONES", color),
              _buildNavIcon(1, Icons.history, "REGISTRO", color),
              _buildNavIcon(2, Icons.settings, "PLANIFICACIÓN", color),
              _buildNavIcon(3, Icons.add_moderator, "DPI-INIT", color),
              _buildNavIcon(4, Icons.auto_awesome, "DPI-ADOPT", color),
              _buildNavIcon(5, Icons.search, "FORENSIC", color),
              const Spacer(),
              Padding(padding: const EdgeInsets.only(bottom: 24), child: _buildEmergencyHandoverButton(color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyHandoverButton(Color color) {
    if (_confirmingHandover) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.05), border: Border.all(color: color.withValues(alpha: 0.1)), borderRadius: BorderRadius.circular(8)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildConfirmationIcon(Icons.gpp_maybe, "SELLAR", Colors.orangeAccent, _runHandover),
            const Divider(color: Colors.white10),
            // [S25-04] Modal para FORZAR
            InkWell(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF000508),
                    shape: RoundedRectangleBorder(side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3))),
                    title: const Text('HANDOVER FORZADO', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                    content: const Text(
                      '⚠️ El handover forzado sella la sesión sin verificación de integridad.\n\n'
                      'Consecuencias:\n'
                      '• Se omite la firma RSA del sello\n'
                      '• La fatiga acumulada se pierde sin registro\n'
                      '• El próximo takeover comenzará sin historial\n\n'
                      'Usar solo si el handover normal falla.',
                      style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.6),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR', style: TextStyle(color: Colors.white38, fontSize: 10))),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                        child: const Text('CONFIRMAR FORZAR', style: TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) _runForcedHandover();
              },
              child: Column(children: [const Icon(Icons.security, color: Colors.redAccent, size: 20), Padding(padding: const EdgeInsets.only(top: 2), child: Text("FORZAR", style: TextStyle(color: Colors.redAccent.withValues(alpha: 0.8), fontSize: 8, fontWeight: FontWeight.bold)))]),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _confirmingHandover = false),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 20)),
              child: const Text("CANCELAR", style: TextStyle(color: Colors.grey, fontSize: 8)),
            )
          ],
        ),
      );
    }
    return IconButton(icon: const Icon(Icons.power_settings_new, color: Colors.redAccent), onPressed: () => setState(() => _confirmingHandover = true), tooltip: "EMERGENCY HANDOVER");
  }

  Widget _buildConfirmationIcon(IconData icon, String label, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Column(children: [Icon(icon, color: color, size: 20), Padding(padding: const EdgeInsets.only(top: 2), child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)))]),
    );
  }

  Color _getThemeColor(String level) {
    if (level.toUpperCase().contains('CRITICAL')) return Colors.redAccent;
    if (level.toUpperCase().contains('GOLD')) return const Color(0xFFFFD700);
    if (level.toUpperCase().contains('SECURITY')) return Colors.orangeAccent;
    return Colors.cyanAccent;
  }

  Widget _buildNavIcon(int index, IconData icon, String label, Color color) {
    final bool active = _navIndex == index;
    return InkWell(
      onTap: () => setState(() => _navIndex = index),
      child: Container(
        width: 80, height: 75,
        decoration: BoxDecoration(border: Border(left: BorderSide(color: active ? color : Colors.transparent, width: 3))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? color : Colors.white24, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: active ? color : Colors.white10, fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color color, Color accent, bool isGov) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) => ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Color.lerp(const Color(0xFF000508).withValues(alpha: 0.8), color.withValues(alpha: 0.1), _shimmerController.value),
              border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.15))),
            ),
            child: Row(
              children: [
                Container(
                  width: 14, height: 14, 
                  decoration: BoxDecoration(
                    color: _isSealed ? Colors.grey : color, 
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: (_isSealed ? Colors.grey : color).withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)]
                  )
                ),
                if (_isSealed) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(3), border: Border.all(color: Colors.grey.withValues(alpha: 0.3))),
                    child: const Text('SEALED', style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ),
                ],
                const SizedBox(width: 20),
                DropdownButtonHideUnderline(
                  child: DropdownButton<Project>(
                    value: _selectedProject,
                    dropdownColor: const Color(0xFF000508),
                    icon: Icon(Icons.keyboard_arrow_down, color: color, size: 16),
                    items: _projects.map((p) => DropdownMenuItem(value: p, child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(p.name, style: TextStyle(color: color, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.2))),
                          child: Text(_activeProjectVersion, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ))).toList(),
                    onChanged: (p) => p != null ? _selectProject(p) : null,
                  ),
                ),
                const SizedBox(width: 12),
                Text(_sprintId, style: TextStyle(color: color.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(width: 20),
                _buildSessionHUD(color),
                const Spacer(),
                if (_driftAlert) _buildDriftWarning(color),
                const SizedBox(width: 16),
                if (!isGov) _buildOperationsHeader(color, accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperationsHeader(Color color, Color accent) {
    return Row(
      children: [
        _buildMetricBox("ZOMBIES", "$_zombies", _zombies > 0 ? Colors.redAccent : color),
        const SizedBox(width: 8),
        _buildActionButton(Icons.cleaning_services, "PURGE", _runPurge, color),
        const SizedBox(width: 8),
        _buildActionButton(Icons.check_circle_outline, "BASELINE", _runBaseline, accent),
      ],
    );
  }

  Widget _buildMetricBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.1), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          Text("$label:", style: TextStyle(color: color.withValues(alpha: 0.4), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildDriftWarning(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)), borderRadius: BorderRadius.circular(4)),
      child: Row(children: [const Icon(Icons.sync_problem, size: 14, color: Colors.orangeAccent), const SizedBox(width: 6), Text("DRIFT DETECTED", style: TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold))]),
    );
  }

  Widget _buildZombieCounter(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: _zombies > 0 ? Colors.red.withValues(alpha: 0.1) : color.withValues(alpha: 0.05), border: Border.all(color: _zombies > 0 ? Colors.redAccent.withValues(alpha: 0.5) : color.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(4)),
      child: Row(children: [Icon(Icons.bug_report, size: 14, color: _zombies > 0 ? Colors.redAccent : color), const SizedBox(width: 6), Text("ZOMBIES: $_zombies", style: TextStyle(color: _zombies > 0 ? Colors.redAccent : color, fontSize: 12, fontWeight: FontWeight.bold))]),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed, Color color) {
    return InkWell(onTap: onPressed, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(border: Border.all(color: color.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(4)), child: Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 8), Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))])));
  }

  Widget _buildSessionHUD(Color color) {
    return Row(
      children: [
        _buildSessionChip(color),
        const SizedBox(width: 16),
        _buildDualTimer(color),
      ],
    );
  }

  Widget _buildSessionChip(Color color) {
    final String displayUuid = _sessionUuid.length > 8 ? _sessionUuid.substring(0, 8) : _sessionUuid;
    return Tooltip(
      message: "Session Fingerprint (UUID): $_sessionUuid\nIdentificador único del hilo de ejecución actual.",
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fingerprint, size: 10, color: color.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Text(displayUuid.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDualTimer(Color color) {
    return Row(
      children: [
        _buildTimerItem(
          icon: Icons.timer, 
          label: "SESSION", 
          startTime: _takeoverTime ?? _sessionStart, 
          color: color,
          tooltip: "SESSION: Tiempo transcurrido desde el inicio de la sesión activa (Takeover).",
        ),
        const SizedBox(width: 12),
        _buildTimerItem(
          icon: Icons.history, 
          label: "IDLE", 
          startTime: _lastActionTs ?? DateTime.now(), 
          color: color.withValues(alpha: 0.6),
          tooltip: "IDLE: Tiempo transcurrido desde la última acción registrada.",
        ),
      ],
    );
  }

  Widget _buildTimerItem({
    required IconData icon, 
    required String label, 
    required DateTime startTime, 
    required Color color,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.withValues(alpha: 0.5)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(color: color.withValues(alpha: 0.4), fontSize: 7, fontWeight: FontWeight.bold)),
              _LiveTimerText(startTime: startTime, color: color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab(Color accent, bool isGov) {
    switch (_navIndex) {
      case 0: return TerminalTab(
        challenge: _challenge, 
        level: _level, 
        description: _description, 
        project: _selectedProject, 
        accent: accent, 
        saturation: _saturation, 
        cus: _cus, // [S25-03]
        bhi: _bhi, // [S25-03]
        isGov: isGov, 
        history: _recentHistory, 
        onViewHistory: () => setState(() => _navIndex = 4), 
        timeRemaining: _timeRemaining, 
        activeTaskId: _activeTaskId, 
        debts: _debts, 
        turns: _turns,
        lastPushDate: _lastPushDate, // [S25-08]
        pushIsStale: _pushIsStale,   // [S25-08]
        onChallengeCleared: () {
          if (_challenge != null) _handledChallenges.add(_challenge!);
          setState(() => _challenge = null);
        },
      );
      case 1: return RegistryTab(project: _selectedProject, backlog: _backlog);
      case 2: return PlanningTab(project: _selectedProject);
      case 3: return const DpiInitWizardScreen(); 
      case 4: return const DpiAdoptWizardScreen(); // [TASK-121-01]
      case 5: return ForensicTab(project: _selectedProject);
      default: return const Center(child: Text("OFFLINE"));
    }
  }
}

class _LiveTimerText extends StatefulWidget {
  final DateTime startTime;
  final Color color;
  const _LiveTimerText({required this.startTime, required this.color});

  @override
  State<_LiveTimerText> createState() => _LiveTimerTextState();
}

class _LiveTimerTextState extends State<_LiveTimerText> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = DateTime.now().difference(widget.startTime);
    
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    
    return Text("$h:$m:$s", style: TextStyle(color: widget.color, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace'));
  }
}

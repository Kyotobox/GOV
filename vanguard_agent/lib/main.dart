import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
      title: 'Vanguard v9.1 SENTINEL',
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

// --- [MODELS & STATE] ---

class ProjectState {
  double cus = 0.0;
  double bhi = 0.0;
  double saturation = 0.0;
  int zombies = 0;
  int turns = 0;
  String sprintId = 'WAITING';
  String activeTaskId = '---';
  String version = '---';
  bool driftAlert = false;
  DateTime? lastActionTs;
  DateTime? takeoverTime;
  String sessionUuid = '---';
  List<dynamic> history = [];
  DateTime sessionStart = DateTime.now();
  int debts = 0;
  bool isSealed = false;
  bool isIntact = true;
  bool hasUpdate = false;
  bool hasChallenge = false;
  
  // Challenge State
  String? challenge;
  String? level;
  String? description;
  List<dynamic> recentHistory = [];
}

class MainHUD extends StatefulWidget {
  const MainHUD({super.key});

  @override
  State<MainHUD> createState() => _MainHUDState();
}

class _MainHUDState extends State<MainHUD> with TickerProviderStateMixin {
  int _navIndex = 0;
  List<Project> _projects = [];
  Project? _selectedProject;
  
  // [S30-SEP] Session Islands: Mapeo de estados locales por búnker
  final Map<String, ProjectState> _states = {};
  
  ProjectState get _currentState => _states[_selectedProject?.id] ?? ProjectState();

  String? _lastSeenChallengeId;
  String _lastPushDate = '---';  
  bool _pushIsStale = false;     
  final Set<String> _handledChallenges = {};
  
  // Tactical Actions
  bool _confirmingHandover = false;
  Timer? _heartbeat;
  
  int _timeRemaining = 0;
  Timer? _countdownTimer;
  
  bool _isExecutingCmd = false;
  String _activeCmdLabel = "";

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

  // [S25-07] Resolver ruta del Oráculo buscando la carpeta 'vault' hacia arriba
  String _resolveOracleRoot() {
    final exePath = Platform.resolvedExecutable;
    Directory current = Directory(p.dirname(exePath));
    
    // Buscar hacia arriba hasta encontrar 'vault' o llegar a la raíz
    while (true) {
      if (Directory(p.join(current.path, 'vault')).existsSync()) {
        return current.path;
      }
      if (current.path == current.parent.path) break;
      current = current.parent;
    }

    // Fallback: Si no se encuentra, usar el directorio del ejecutable o bin/parent
    final exeDir = Directory(p.dirname(exePath));
    if (p.basename(exeDir.path).toLowerCase() == 'bin' || 
        p.basename(exeDir.path).toLowerCase() == 'release' || 
        p.basename(exeDir.path).toLowerCase() == 'debug') {
      return exeDir.parent.path;
    }
    return exeDir.path;
  }

  Future<void> _loadSettings() async {
    final oracleRoot = _resolveOracleRoot();
    final masterFleetPath = p.join(oracleRoot, 'vault', 'intel', 'fleet_registry.json');
    final logFile = File(p.join(oracleRoot, 'vanguard_crash.log'));
    
    try {
      final fleetFile = File(masterFleetPath);
      if (await fleetFile.exists()) {
        final bytes = await fleetFile.readAsBytes();
        final data = jsonDecode(utf8.decode(bytes));
        final List<dynamic> bunkers = data['bunkers'] ?? data['projects'] ?? [];
        _projects = bunkers.map((e) {
          final bunker = Project.fromJson(e);
          // Priorizar po_private.xml para gobernanza de KYOTOBOX
          final bool isGov = bunker.name.contains('GOV') || bunker.rootPath.contains('antigravity_dpi');
          return Project(
            id: bunker.id,
            name: bunker.name,
            rootPath: bunker.rootPath,
            keyPath: isGov 
              ? p.join(oracleRoot, 'vault', 'po_private.xml')
              : p.join(bunker.rootPath, 'vault', 'intel', 'signature_history.json'),
          );
        }).toList();
        
        // Agregar el Oráculo dinámicamente si no está
        if (!_projects.any((p) => p.isGovMode)) {
          _projects.add(Project(
            id: 'gov', 
            name: 'KYOTOBOX - GOV', 
            rootPath: oracleRoot, 
            keyPath: p.join(oracleRoot, 'vault', 'po_private.xml')
          ));
        }
      } else {
        // Fallback robusto al Oracle Root
        _projects = [
          Project(
            id: 'gov', 
            name: 'KYOTOBOX - GOV', 
            rootPath: oracleRoot, 
            keyPath: p.join(oracleRoot, 'vault', 'po_private.xml')
          )
        ];
      }
    } catch (e, stack) {
      debugPrint('[VANGUARD-FATAL] Launch error: $e');
      try {
        await logFile.writeAsString('[${DateTime.now().toIso8601String()}] ERROR: $e\nSTACK: $stack\n');
      } catch (_) {}
      
      _projects = [
        Project(
          id: 'gov', 
          name: 'KYOTOBOX - GOV', 
          rootPath: oracleRoot, 
          keyPath: p.join(oracleRoot, 'vault', 'po_private.xml')
        )
      ];
    }

    if (mounted && _projects.isNotEmpty) {
      // Priorizar el núcleo de gobernanza para que sea el primero en mostrarse (V8.0)
      final gov = _projects.firstWhere((p) => p.isGovMode, orElse: () => _projects.first);
      _selectProject(gov);
    }
  }

  void _selectProject(Project project) {
    _subscription?.cancel();
    setState(() {
      _selectedProject = project;
      _handledChallenges.clear(); 
      if (project.isGovMode) _navIndex = 0;
    });
    _startWatcher(project);
    _refreshTelemetry(project);
    _loadSessionTimer(project);
  }

  Future<void> _loadSessionTimer(Project project) async {
    final state = _states.putIfAbsent(project.id, () => ProjectState());
    final lockFile = File(p.join(project.rootPath, '.meta', 'SESSION_LOCKED'));
    if (await lockFile.exists()) {
      final ts = await lockFile.lastModified();
      setState(() => state.sessionStart = ts);
    } else {
      setState(() => state.sessionStart = DateTime.now());
    }

    // [TASK-DPI-126-11] Load Active Session Takeover Time
    final sessionLock = File(p.join(project.rootPath, '.meta', 'session.lock'));
    if (await sessionLock.exists()) {
      try {
        final bytes = await sessionLock.readAsBytes();
        final data = jsonDecode(utf8.decode(bytes));
        if (data['timestamp'] != null) {
          setState(() {
            state.takeoverTime = DateTime.parse(data['timestamp']);
            state.sessionUuid = data['chat_uuid'] ?? 'UNKNOWN';
          });
        }
      } catch (_) {}
    } else {
       setState(() {
         state.takeoverTime = null;
         state.sessionUuid = 'UNLOCKED';
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
    final state = _states.putIfAbsent(project.id, () => ProjectState());
    final double lastSaturation = state.saturation;

    // 1. Challenge
    final cFile = File(p.join(project.rootPath, 'vault', 'intel', 'challenge.json'));
    if (await cFile.exists()) {
      try {
        final bytes = await cFile.readAsBytes();
        final data = jsonDecode(utf8.decode(bytes));
        final String newId = data['challenge'];
        
        if (!_handledChallenges.contains(newId)) {
          if (mounted) {
            setState(() {
              state.challenge = newId;
              state.level = data['level'];
              state.description = data['description'];
            });
          }
        } else {
          if (mounted) setState(() => state.challenge = null);
        }
      } catch (_) {}
    } else { 
      if (mounted) setState(() => state.challenge = null); 
    }

    // 1b. Timeout Check
    _countdownTimer?.cancel();
    if (state.challenge != null) {
      final cFile = File(p.join(project.rootPath, 'vault', 'intel', 'challenge.json'));
      if (await cFile.exists()) {
        try {
          final bytes = await cFile.readAsBytes();
          final data = jsonDecode(utf8.decode(bytes));
          final tsStr = data['timestamp'];
          if (tsStr != null) {
            final ts = DateTime.parse(tsStr);
            final diff = DateTime.now().difference(ts).inSeconds;
            if (diff > 60) {
              if (mounted) setState(() { state.challenge = null; _timeRemaining = 0; });
            } else {
              setState(() => _timeRemaining = 60 - diff);
              _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
                if (_timeRemaining > 0) {
                   if (mounted) setState(() => _timeRemaining--);
                } else {
                  t.cancel();
                  if (mounted) setState(() => state.challenge = null);
                }
              });
            }
          }
        } catch (_) {}
      }
    }

    // 2. SHS Pulse
    final pFile = File(p.join(project.rootPath, 'vault', 'intel', 'intel_pulse.json'));
    if (await pFile.exists()) {
      try {
        final bytes = await pFile.readAsBytes();
        final data = jsonDecode(utf8.decode(bytes));
        if (mounted) {
          setState(() {
            state.cus = (data['cp_fatigue'] ?? data['cp'] ?? 0.0) / 100.0;
            state.bhi = (data['bhi'] ?? data['hygiene']?['bhi'] ?? 0.0) / 100.0;
            state.saturation = (data['saturation'] ?? 0.0) / 100.0;
            state.zombies = (data['zombies'] ?? 0);
            state.driftAlert = data['drift_alert'] ?? false;
            state.turns = data['cp_detail']?['tools']?.toInt() ?? 0;
            state.sessionUuid = data['session_uuid'] ?? state.sessionUuid;
            if (data['cp_detail']?['last_action_ts'] != null) {
              state.lastActionTs = DateTime.parse(data['cp_detail']['last_action_ts']);
            }
            if (data['start_timestamp'] != null) {
              state.takeoverTime = DateTime.parse(data['start_timestamp']);
            }
            
            final bool isNewChallenge = state.challenge != null && state.challenge != _lastSeenChallengeId;
            final bool isCriticalHit = state.saturation >= 0.90 && lastSaturation < 0.90;

            if (isNewChallenge || isCriticalHit) {
               SystemSound.play(SystemSoundType.alert);
               _shimmerController.forward(from: 0.0);
               _lastSeenChallengeId = state.challenge;
            }

            if (state.saturation >= 0.90 || (state.challenge != null && (state.level?.toUpperCase().contains('BLACK') ?? false))) {
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
        final bytes = await bFile.readAsBytes();
        final data = jsonDecode(utf8.decode(bytes));
        if (mounted) {
          setState(() {
            state.sprintId = 'WAITING';
            final sprints = (data['sprints'] as List?) ?? [];
            if (sprints.isNotEmpty) {
              final active = sprints.firstWhere((s) => s['status'] == 'IN_PROGRESS', orElse: () => null);
              if (active != null) {
                state.sprintId = active['id'];
                final tasks = (active['tasks'] as List?) ?? [];
                final running = tasks.firstWhere((t) => t['status'] == 'IN_PROGRESS', orElse: () => null);
                state.activeTaskId = running != null ? running['id'] : '---';
              }
            }

            state.version = data['version'] ?? data['kernel_version'] ?? 'v8.2.0';
            int debts = 0;
            for (var sprint in sprints) {
              final tasks = sprint['tasks'] as List? ?? [];
              debts += tasks.where((t) => (t['label'] == 'DEBT' || t['id'].contains('DEBT')) && t['status'] != 'DONE').length;
            }
            state.debts = debts;

            // [TASK-V9-02] Update Detection
            final binDir = Directory(p.join(project.rootPath, 'bin'));
            if (binDir.existsSync()) {
              state.hasUpdate = binDir.listSync().any((f) => f.path.endsWith('.update'));
            }
            state.isIntact = !(data['drift_alert'] ?? false); // Drift alert usually means compromise
            
            // [TASK-V9-02b] Fleet Challenge Detection
            final cFile = File(p.join(project.rootPath, 'vault', 'intel', 'challenge.json'));
            state.hasChallenge = cFile.existsSync();
          });
        }
      } catch (_) {}
    }

    // 4. History
    final hFile = File(p.join(project.rootPath, 'vault', 'intel', 'signature_history.json'));
    if (await hFile.exists()) {
      try {
        final bytes = await hFile.readAsBytes();
        final List<dynamic> history = jsonDecode(utf8.decode(bytes));
        if (mounted) setState(() => state.recentHistory = history.take(5).toList());
      } catch (_) {}
    }
  }

  // --- [TACTICAL ACTIONS] ---

  String _getGovPath(String root) {
    // [V9.1] Prioritize bin/gov.exe, then root, then oracle bin
    final binPath = p.join(root, 'bin', 'gov.exe');
    if (File(binPath).existsSync()) return binPath;
    final rootPath = p.join(root, 'gov.exe');
    if (File(rootPath).existsSync()) return rootPath;
    
    // Fallback: If node is being bootstrapped, maybe it only exists as an update
    final updatePath = p.join(root, 'bin', 'gov.exe.update');
    if (File(updatePath).existsSync()) return updatePath;
    
    return "gov"; // Rely on PATH as last resort
  }

  void _showStatus(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.shareTechMono(fontSize: 11, fontWeight: FontWeight.bold, color: isError ? Colors.redAccent : Colors.cyanAccent)),
        backgroundColor: Colors.black.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(side: BorderSide(color: (isError ? Colors.redAccent : Colors.cyanAccent).withValues(alpha: 0.3))),
      )
    );
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
    setState(() { _isExecutingCmd = true; _activeCmdLabel = "PURGING"; });
    _showStatus("[GOV] Iniciando Housekeeping...");
    try {
      final res = await Process.run(_getGovPath(root), ['housekeeping'], workingDirectory: root);
      if (res.exitCode == 0) {
        _showStatus("[GOV] Purga completada.");
      } else {
        _showStatus("[ERROR] Purga fallida: ${res.stderr}", isError: true);
      }
      _refreshTelemetry(_selectedProject!);
    } catch (e) {
      _showStatus("[FATAL] Error de sistema: $e", isError: true);
    }
    setState(() => _isExecutingCmd = false);
  }

  Future<void> _runAudit() async {
    final root = _selectedProject?.rootPath;
    if (root == null) return;
    setState(() { _isExecutingCmd = true; _activeCmdLabel = "AUDITING"; });
    _showStatus("[GOV] Iniciando Auditoría Integral...");
    try {
      final res = await Process.run(_getGovPath(root), ['audit'], workingDirectory: root);
      _showStatus("[GOV] Registro de auditoría actualizado.");
      _refreshTelemetry(_selectedProject!);
    } catch (e) {
      _showStatus("[ERROR] Auditoría interrumpida: $e", isError: true);
    }
    setState(() => _isExecutingCmd = false);
  }

  Future<void> _runHandover() async {
    final root = _selectedProject?.rootPath;
    if (root == null) return;
    try {
      await Process.run(_getGovPath(root), ['handover'], workingDirectory: root);
      if (mounted) {
        setState(() {
          _confirmingHandover = false;
          _currentState.isSealed = true; 
        });
      }
      _refreshTelemetry(_selectedProject!);
    } catch (_) {}
  }

  Future<void> _runUpgrade() async {
    final root = _selectedProject?.rootPath;
    if (root == null) return;
    setState(() { _isExecutingCmd = true; _activeCmdLabel = "UPGRADING"; });
    _showStatus("[GOV] Iniciando Protocolo de Hot-Swap...");
    try {
      if (mounted) setState(() => _navIndex = 1); // Switch to terminal to see progress
      final res = await Process.run(_getGovPath(root), ['upgrade'], workingDirectory: root);
      if (res.exitCode == 0) {
         _showStatus("[DONE] Upgrade v9.1 activo.");
      } else {
         _showStatus("[VANGUARD] Upgrade requiere intervención: ${res.stderr}", isError: true);
      }
      _refreshTelemetry(_selectedProject!);
    } catch (e) {
       _showStatus("[FATAL] System error during upgrade: $e", isError: true);
    }
    setState(() => _isExecutingCmd = false);
  }

  Future<void> _runForcedHandover() async {
    final root = _selectedProject?.rootPath;
    if (root == null) return;
    if (mounted) setState(() => _confirmingHandover = false);
    try {
      await Process.run(_getGovPath(root), ['handover', '--force'], workingDirectory: root);
      if (mounted) setState(() => _currentState.isSealed = true); 
      _refreshTelemetry(_selectedProject!);
    } catch (_) {}
  }



  @override
  Widget build(BuildContext context) {
    final bool isGov = _selectedProject?.isGovMode ?? false;
    final state = _states[_selectedProject?.id] ?? ProjectState();
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final Color projectColor = _getProjectColor(_selectedProject?.name ?? "");
        final Color themeColor = state.challenge == null ? projectColor : _getThemeColor(state.level ?? "");
        final Color accent = Color.lerp(themeColor, Colors.redAccent, isGov ? 0.0 : state.saturation)!;
        final Color bgColor = state.challenge == null ? const Color(0xFF000508) : themeColor.withValues(alpha: 0.1);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF000508),
              gradient: state.challenge != null ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [bgColor, const Color(0xFF000508)]) : null,
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    _buildSidebar(accent),
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
                // [V9.1] Bottom Left Version HUD
                Positioned(
                  bottom: 24, left: 104,
                  child: _buildBottomHUD(accent),
                ),
                // [TASK-119-06] BlackGate Critical Pulse Overlay
                if (state.saturation >= 0.90 || (state.challenge != null && (state.level?.toUpperCase().contains('BLACK') ?? false))) 
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
            color: Colors.black.withValues(alpha: 0.9), // Darker for better contrast
          ),
          child: Column(
            children: [
              const SizedBox(height: 32),
              _buildNavIcon(0, Icons.terminal, "OPS", color),
              _buildNavIcon(1, Icons.history, "LEDGER", color),
              _buildNavIcon(2, Icons.map, "PLAN", color),
              const Divider(color: Colors.white10),
              _buildNavIcon(3, Icons.add_moderator, "INIT", color),
              _buildNavIcon(4, Icons.auto_awesome, "ADOPT", color),
              _buildNavIcon(5, Icons.search, "FORENSIC", color),
              const Spacer(),
              _buildFleetRadar(color),
              const SizedBox(height: 20),
              Padding(padding: const EdgeInsets.only(bottom: 24), child: _buildEmergencyHandoverButton(color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFleetRadar(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: _projects.map((p) {
          final pState = _states[p.id] ?? ProjectState();
          final bool needsSig = pState.hasChallenge;
          final bool needsUpgrade = pState.hasUpdate;
          final bool isSelected = _selectedProject?.id == p.id;
          
          return Tooltip(
            message: "Node: ${p.name}\n${needsSig ? 'REQUIERE FIRMA RSA' : ''}${needsUpgrade ? '\nUPDATE DISPONIBLE' : ''}",
            child: InkWell(
              onTap: () => _selectProject(p),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                width: 40, height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(4),
                  color: isSelected ? color.withValues(alpha: 0.05) : Colors.transparent,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(p.name[0].toUpperCase(), style: TextStyle(color: isSelected ? color : Colors.white24, fontWeight: FontWeight.bold, fontSize: 13)),
                    if (needsSig) Positioned(top: 2, right: 2, child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle))),
                    if (needsUpgrade) Positioned(bottom: 2, right: 2, child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle))),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomHUD(Color color) {
     final state = _states[_selectedProject?.id] ?? ProjectState();
     return ClipRRect(
       borderRadius: BorderRadius.circular(4),
       child: BackdropFilter(
         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
         child: Container(
           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
           decoration: BoxDecoration(
             color: Colors.black.withValues(alpha: 0.8),
             border: Border.all(color: color.withValues(alpha: 0.2)),
           ),
           child: Row(
             mainAxisSize: MainAxisSize.min,
             children: [
               const Icon(Icons.security, size: 10, color: Colors.white24),
               const SizedBox(width: 8),
               Text("GOV ${state.version}-SENTINEL", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white38)),
               const SizedBox(width: 12),
               const VerticalDivider(color: Colors.white10),
               const SizedBox(width: 12),
               Text(_selectedProject?.name.toUpperCase() ?? "UNKNOWN", style: TextStyle(color: _getProjectColor(_selectedProject?.name ?? ""), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
               const SizedBox(width: 12),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                 decoration: BoxDecoration(color: state.isIntact ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2)),
                 child: Text(state.isIntact ? "SEALED" : "TAMPERED", style: TextStyle(color: state.isIntact ? Colors.greenAccent : Colors.redAccent, fontSize: 7, fontWeight: FontWeight.bold)),
               )
             ],
           ),
         ),
       ),
     );
  }

  Widget _buildEmergencyHandoverButton(Color color) {
    final state = _states[_selectedProject?.id] ?? ProjectState();
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
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '⚠️ El handover forzado sella la sesión sin verificación de integridad.\n\n'
                          'Consecuencias:\n'
                          '• Se omite la firma RSA del sello\n'
                          '• La fatiga acumulada se pierde sin registro\n'
                          '• El próximo takeover comenzará sin historial\n\n',
                          style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.6),
                        ),
                        Text('SESSION UUID: ${state.sessionUuid.toUpperCase()}',
                            style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 10)),
                        const SizedBox(height: 4),
                        Text('DNA HASH: [${state.sessionUuid.hashCode.toRadixString(16).toUpperCase()}]',
                            style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 10)),
                      ],
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

  Color _getProjectColor(String name) {
    final String n = name.toUpperCase();
    if (n.contains('GOV') || n.contains('KYOTO')) return const Color(0xFFFFD700); // Dorado
    if (n.contains('BASE2')) return Colors.blueAccent; // Azul
    if (n.contains('MINIDUO')) return Colors.deepPurpleAccent; // Violeta
    return Colors.cyanAccent; // Default
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
    final state = _states[_selectedProject?.id] ?? ProjectState();
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
                    color: state.isSealed ? Colors.grey : color, 
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: (state.isSealed ? Colors.grey : color).withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)]
                  )
                ),
                if (state.isSealed) ...[
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
                    items: _projects.map((p) {
                      final pState = _states[p.id] ?? ProjectState();
                      final bool pNeedsSig = pState.hasChallenge;
                      
                      return DropdownMenuItem(value: p, child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (pNeedsSig) ...[
                            const Icon(Icons.circle, color: Colors.orangeAccent, size: 8),
                            const SizedBox(width: 8),
                          ],
                          Text(p.name, style: TextStyle(color: pNeedsSig ? Colors.orangeAccent : color, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.2))),
                            child: Text(pState.version, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ));
                    }).toList(),
                    onChanged: (p) => p != null ? _selectProject(p) : null,
                  ),
                ),
                const SizedBox(width: 12),
                _headerMetric(label: 'CUS', value: state.cus, color: _getMetricColor(state.cus)),
                _headerMetric(label: 'BHI', value: state.bhi, color: _getMetricColor(state.bhi)),
                _headerMetric(label: 'SHS', value: state.saturation, color: _getMetricColor(state.saturation)),
                const SizedBox(width: 20),
                _buildSessionHUD(color),
                const Spacer(),
                if (state.driftAlert) _buildDriftWarning(color),
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
    final state = _states[_selectedProject?.id] ?? ProjectState();
    final bool needsUpgrade = !state.isIntact && state.hasUpdate;
    
    return Row(
      children: [
        _headerMetric(label: 'ZOMBIES', value: state.zombies.toDouble(), color: _getMetricColor(state.zombies.toDouble())),
        const SizedBox(width: 8),
        _buildActionButton(Icons.cleaning_services, "PURGE", _runPurge, color),
        const SizedBox(width: 8),
        if (state.hasUpdate)
          _buildActionButton(
            Icons.system_update, 
            "UPGRADE", 
            _runUpgrade, 
            needsUpgrade ? Colors.orangeAccent : Colors.greenAccent
          ),
        const SizedBox(width: 8),
        _buildActionButton(
          Icons.security, 
          "AUDIT", 
          _runAudit, 
          needsUpgrade ? Colors.orangeAccent : color
        ),
      ],
    );
  }

  Color _getMetricColor(double val) {
    if (val >= 0.90) return Colors.redAccent;
    if (val >= 0.80) return Colors.orangeAccent;
    return const Color(0xFF00E5FF);
  }

  Widget _headerMetric({required String label, required double value, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 2),
          Text("${(value * 100).toInt()}%", style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // DEPRECATED: Use _buildHeaderMetric or _buildBottomHUD


  Widget _buildDriftWarning(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)), borderRadius: BorderRadius.circular(4)),
      child: Row(children: [const Icon(Icons.sync_problem, size: 14, color: Colors.orangeAccent), const SizedBox(width: 6), Text("DRIFT DETECTED", style: TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold))]),
    );
  }


  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed, Color color) {
    final bool isBusy = _isExecutingCmd && label.contains(_activeCmdLabel.substring(0, 3));
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: isBusy ? 0.95 : 1.0,
        child: InkWell(
          onTap: isBusy ? null : onPressed, 
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
            decoration: BoxDecoration(
              color: isBusy ? color.withValues(alpha: 0.1) : Colors.transparent,
              border: Border.all(color: isBusy ? color : color.withValues(alpha: 0.3)), 
              borderRadius: BorderRadius.circular(4),
              boxShadow: isBusy ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10)] : null,
            ), 
            child: Row(
              children: [
                if (isBusy) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24))
                else Icon(icon, size: 16, color: color), 
                const SizedBox(width: 8), 
                Text(isBusy ? "EXECUTING..." : label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))
              ],
            ),
          ),
        ),
      ),
    );
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
    final String displayUuid = _currentState.sessionUuid.length > 8 ? _currentState.sessionUuid.substring(0, 8) : _currentState.sessionUuid;
    return Tooltip(
      message: "Session Fingerprint (UUID): ${_currentState.sessionUuid}\nIdentificador único del hilo de ejecución actual.",
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
          startTime: _currentState.takeoverTime ?? _currentState.sessionStart, 
          color: color,
          tooltip: "SESSION: Tiempo transcurrido desde el inicio de la sesión activa (Takeover).",
        ),
        const SizedBox(width: 12),
        _buildTimerItem(
          icon: Icons.history, 
          label: "IDLE", 
          startTime: _currentState.lastActionTs ?? DateTime.now(), 
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
    final state = _states[_selectedProject?.id] ?? ProjectState();
    
    switch (_navIndex) {
      case 0: return TerminalTab(
        challenge: state.challenge, 
        level: state.level, 
        description: state.description, 
        project: _selectedProject, 
        accent: accent, 
        saturation: state.saturation, 
        cus: state.cus, 
        bhi: state.bhi, 
        isGov: isGov, 
        version: state.version, 
        history: state.recentHistory, 
        onViewHistory: () => setState(() => _navIndex = 1), 
        pushIsStale: _pushIsStale,
        onChallengeCleared: () {
          if (state.challenge != null) _handledChallenges.add(state.challenge!);
          setState(() => state.challenge = null);
        },
        // [S120] Added missing parameters
        timeRemaining: _timeRemaining,
        activeTaskId: state.activeTaskId,
        debts: state.debts,
        turns: state.turns,
        lastPushDate: _lastPushDate,
      );
      case 1: return RegistryTab(project: _selectedProject, backlog: null); // Backlog not stored in state yet, but null is fine for now
      case 2: return PlanningTab(project: _selectedProject);
      case 3: return const DpiInitWizardScreen(); 
      case 4: return const DpiAdoptWizardScreen(); 
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

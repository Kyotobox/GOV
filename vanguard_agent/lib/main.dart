import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:watcher/watcher.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VanguardAgent());
}

class Project {
  String id;
  String name;
  String rootPath;
  String keyPath;

  Project({
    required this.id,
    required this.name,
    required this.rootPath,
    required this.keyPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rootPath': rootPath,
        'keyPath': keyPath,
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'],
        name: json['name'],
        rootPath: json['rootPath'],
        keyPath: json['keyPath'],
      );
}

class VanguardAgent extends StatelessWidget {
  const VanguardAgent({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vanguard Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const AgentHome(),
    );
  }
}

class ProjectUtils {
  static Future<Map<String, dynamic>> validateProject(Project project) async {
    final root = Directory(project.rootPath);
    final keyFile = File(project.keyPath);
    
    if (!await root.exists()) return {'valid': false, 'error': 'Ruta de proyecto no encontrada.'};
    if (!await keyFile.exists()) return {'valid': false, 'error': 'Archivo de clave no encontrado.'};
    
    try {
      final content = await keyFile.readAsString();
      if (!content.contains('<RSAKeyValue>')) return {'valid': false, 'error': 'El archivo no es una clave RSA válida.'};
      
      final match = RegExp(r'<ProjectId>(.*)</ProjectId>').firstMatch(content);
      final boundId = match?.group(1);
      
      if (boundId == null) return {'valid': true, 'bound': false};
      if (boundId == project.id) return {'valid': true, 'bound': true};
      
      // Permissive: allow using the key even if bound to another project, just warn
      return {'valid': true, 'bound': false, 'warning': 'Esta clave está vinculada a $boundId'};
    } catch (e) {
      return {'valid': false, 'error': 'Error leyendo clave: $e'};
    }
  }

  static Future<void> bindKey(Project project) async {
    final keyFile = File(project.keyPath);
    String content = await keyFile.readAsString();
    if (content.contains('<ProjectId>')) {
      // Ya está vinculada. Evitamos colisión de sobreescritura.
      return;
    }
    if (content.contains('</RSAKeyValue>')) {
      content = content.replaceFirst('</RSAKeyValue>', '</RSAKeyValue>\n<ProjectId>${project.id}</ProjectId>');
      await keyFile.writeAsString(content);
    }
  }
}

class AgentHome extends StatefulWidget {
  const AgentHome({super.key});

  @override
  State<AgentHome> createState() => _AgentHomeState();
}

class _AgentHomeState extends State<AgentHome> {
  List<Project> _projects = [];
  Project? _selectedProject;
  
  // Tactical State
  String? _challenge;
  String? _level;
  String? _lastApprovedId;
  String? _lastApprovedLevel;
  String? _lastApprovedProjectName;
  
  String? _status = 'Inicie un proyecto...';
  bool _isSigning = false;
  bool _kernelModeActive = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}/vanguard_settings.json');
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final List<dynamic> data = jsonDecode(content);
        setState(() {
          _projects = data.map((e) => Project.fromJson(e)).toList();
          if (_projects.isNotEmpty) {
            _selectProject(_projects.first);
          }
        });
      } catch (e) {
        debugPrint('Error cargando settings: $e');
      }
    }
  }

  Future<void> _saveSettings() async {
    final directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}/vanguard_settings.json');
    await file.writeAsString(jsonEncode(_projects.map((e) => e.toJson()).toList()));
  }

  void _selectProject(Project project, {bool force = false}) {
    _subscription?.cancel();
    
    ProjectUtils.validateProject(project).then((res) {
      if (!res['valid']) {
        setState(() => _status = 'ERROR: ${res['error']}');
        return;
      }
      
      if (res['bound'] == false && !force) {
        _showBindDialog(project);
        return;
      }

      setState(() {
        _selectedProject = project;
        _challenge = null;
        _level = null;
        _isSigning = false;
        _kernelModeActive = false;
        _status = 'Vigilando: ${project.name}';
      });
      _startWatcher(project);
    });
  }

  void _showBindDialog(Project project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vincular Clave'),
        content: Text('Esta clave no está vinculada a ningún proyecto. ¿Desea vincularla a "${project.name}" para evitar colisiones?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _selectProject(project, force: true);
            },
            child: const Text('No, usar así'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ProjectUtils.bindKey(project);
              if (!context.mounted) return;
              Navigator.pop(context);
              _selectProject(project);
            },
            child: const Text('Vincular e Iniciar'),
          ),
        ],
      ),
    );
  }

  void _startWatcher(Project project) {
    final intelDir = p.join(project.rootPath, 'vault', 'intel');
    if (!Directory(intelDir).existsSync()) {
      setState(() => _status = 'ERROR: vault/intel no existe en ${project.name}');
      return;
    }

    final watcher = DirectoryWatcher(intelDir);
    _subscription = watcher.events.listen((event) {
      if (event.path.endsWith('challenge.json')) {
        if (event.type == ChangeType.ADD || event.type == ChangeType.MODIFY) {
          _loadChallenge(project);
        } else if (event.type == ChangeType.REMOVE) {
          setState(() {
            _challenge = null;
            _level = null;
          });
        }
      }
    });
    _loadChallenge(project);
  }

  Future<void> _loadChallenge(Project project) async {
    final file = File(p.join(project.rootPath, 'vault', 'intel', 'challenge.json'));
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        if (content.isEmpty) return;
        final data = jsonDecode(content);
        
        if (data['challenge'] == _lastApprovedId) return;

        setState(() {
          _challenge = data['challenge'];
          _level = data['level'] ?? 'TACTICAL';
          _status = '¡NUEVO DESAFÍO EN ${project.name}! ⚠️';
        });
        
        _playLevelAlarm(_level!);
      } catch (e) {
        debugPrint('Error leyendo challenge: $e');
      }
    } else {
      setState(() {
        _challenge = null;
        _level = null;
      });
    }
  }

  void _playLevelAlarm(String? level) {
    if (level == 'BLACK-GATE') {
      // Patron de emergencia: 5 alertas rápidas
      for (int i = 0; i < 5; i++) {
        Future.delayed(Duration(milliseconds: i * 200), () => SystemSound.play(SystemSoundType.alert));
      }
    } else if (level == 'KERNEL-CORE') {
      // Patron Gold: 3 alertas
      for (int i = 0; i < 3; i++) {
        Future.delayed(Duration(milliseconds: i * 400), () => SystemSound.play(SystemSoundType.alert));
      }
    } else if (level == 'KERNEL') {
      // Patron Red: 2 alertas
      for (int i = 0; i < 2; i++) {
        Future.delayed(Duration(milliseconds: i * 600), () => SystemSound.play(SystemSoundType.alert));
      }
    } else {
      // TACTICAL/OPERATIONAL: 1 solo click/alert
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> _signChallenge() async {
    if (_selectedProject == null || _challenge == null || _isSigning) return;

    setState(() {
      _isSigning = true;
      _status = 'Firmando via PowerShell...';
    });

    try {
      final scriptPath = p.join(_selectedProject!.rootPath, 'scripts', 'sign_challenge.ps1');
      
      final result = await Process.run('powershell', [
        '-ExecutionPolicy', 'Bypass',
        '-File', scriptPath,
        '-Challenge', _challenge!,
        '-KeyPath', _selectedProject!.keyPath,
      ], workingDirectory: _selectedProject!.rootPath);

      if (result.exitCode == 0) {
        setState(() {
          _lastApprovedId = _challenge;
          _lastApprovedLevel = _level;
          _lastApprovedProjectName = _selectedProject!.name;
          _challenge = null;
          _level = null;
          _isSigning = false;
          _kernelModeActive = false;
          _status = 'FIRMADO ENVIADO ✅';
        });
      } else {
        throw Exception(result.stderr);
      }
    } catch (e) {
      setState(() {
        _isSigning = false;
        _status = 'ERROR: $e';
      });
    }
  }

  void _sendPanic() async {
    if (_selectedProject == null) return;
    final sigFile = File(p.join(_selectedProject!.rootPath, 'vault', 'intel', 'signature.json'));
    await sigFile.writeAsString(jsonEncode({
      'signature': 'PANIC_000000',
      'timestamp': DateTime.now().toIso8601String(),
    }));
    setState(() {
      _status = '¡PÁNICO ENVIADO! 🚨';
    });
  }

  void _rejectChallenge() async {
    if (_selectedProject == null) return;
    final sigFile = File(p.join(_selectedProject!.rootPath, 'vault', 'intel', 'signature.json'));
    await sigFile.writeAsString(jsonEncode({
      'signature': 'REJECT_000000',
      'timestamp': DateTime.now().toIso8601String(),
    }));
    setState(() {
      _challenge = null;
      _level = null;
      _kernelModeActive = false;
      _status = 'RECHAZADO EXPLÍCITAMENTE.';
    });
  }

  void _showAddProjectDialog() {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final rootController = TextEditingController();
    final keyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Añadir Proyecto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(controller: idController, decoration: const InputDecoration(labelText: 'ID del Proyecto (técnico)', hintText: 'ej: base2-default')),
              Row(
                children: [
                   Expanded(child: TextField(controller: rootController, decoration: const InputDecoration(labelText: 'Ruta del Proyecto'))),
                   IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: () async {
                      String? path = await FilePicker.platform.getDirectoryPath();
                      if (path != null) setDialogState(() => rootController.text = path);
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(child: TextField(controller: keyController, decoration: const InputDecoration(labelText: 'Ruta de Clave Privada (.xml)'))),
                  IconButton(
                    icon: const Icon(Icons.file_open),
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['xml'],
                      );
                      if (result != null) setDialogState(() => keyController.text = result.files.single.path!);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final p = Project(
                  id: idController.text.isEmpty ? nameController.text.replaceAll(' ', '-').toLowerCase() : idController.text,
                  name: nameController.text,
                  rootPath: rootController.text,
                  keyPath: keyController.text,
                );
                setState(() => _projects.add(p));
                _saveSettings();
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProjectDialog(Project project) {
    final nameController = TextEditingController(text: project.name);
    final idController = TextEditingController(text: project.id);
    final rootController = TextEditingController(text: project.rootPath);
    final keyController = TextEditingController(text: project.keyPath);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Proyecto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(controller: idController, decoration: const InputDecoration(labelText: 'ID del Proyecto')),
              Row(
                children: [
                  Expanded(child: TextField(controller: rootController, decoration: const InputDecoration(labelText: 'Ruta del Proyecto'))),
                  IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: () async {
                      String? path = await FilePicker.platform.getDirectoryPath();
                      if (path != null) setDialogState(() => rootController.text = path);
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(child: TextField(controller: keyController, decoration: const InputDecoration(labelText: 'Ruta de Clave (.xml)'))),
                  IconButton(
                    icon: const Icon(Icons.file_open),
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['xml'],
                      );
                      if (result != null) setDialogState(() => keyController.text = result.files.single.path!);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  project.id = idController.text;
                  project.name = nameController.text;
                  project.rootPath = rootController.text;
                  project.keyPath = keyController.text;
                });
                _saveSettings();
                Navigator.pop(context);
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isKernel = _level == 'KERNEL';
    final bool isKernelCore = _level == 'KERNEL-CORE';
    final bool isTactical = _level == 'TACTICAL';
    final bool isBlackGate = _level == 'BLACK-GATE';
    final bool isOperational = _level != null && !isKernel && !isKernelCore && !isTactical && !isBlackGate;
    final bool showInertiaBreaker = (isKernel || isKernelCore || isBlackGate) && !_kernelModeActive;
    
    final Color bgColor = isBlackGate ? Colors.black
                        : isKernelCore ? const Color(0xFF1A1A00) 
                        : isKernel ? const Color(0xFF1A0000) 
                        : isTactical ? const Color(0xFF1A0D00)
                        : const Color(0xFF001A1A);
    final Color accentColor = isBlackGate ? Colors.redAccent.shade400
                            : isKernelCore ? Colors.amberAccent 
                            : isKernel ? Colors.redAccent 
                            : isTactical ? Colors.orangeAccent
                            : Colors.cyanAccent;

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: bgColor,
        appBarTheme: AppBarTheme(
          backgroundColor: isBlackGate ? Colors.black : isKernelCore ? Colors.amber.shade900 : isKernel ? Colors.red.shade900 : Colors.cyan.shade900,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            isBlackGate ? '☠ VANGUARD: BLACK GATE (EMERGENCY)' :
            isKernelCore ? '⚖ VANGUARD: GOLD INMUTABLE' :
            isKernel ? '⚠️ VANGUARD: KERNEL RED' : 
            isTactical ? '📈 VANGUARD: TACTICAL ORANGE' :
            '🔒 VANGUARD: OPERATIONAL v5.2-DPI',
            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13),
          ),
          actions: [
            IconButton(onPressed: _showAddProjectDialog, icon: const Icon(Icons.add_business)),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              const DrawerHeader(child: Text('PROYECTOS ACTIVOS', style: TextStyle(fontSize: 20))),
              ..._projects.map((p) => ListTile(
                    title: Text(p.name),
                    subtitle: Text(p.rootPath, overflow: TextOverflow.ellipsis),
                    selected: _selectedProject?.id == p.id,
                    onTap: () {
                      _selectProject(p);
                      Navigator.pop(context);
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showEditProjectDialog(p)),
                        IconButton(icon: const Icon(Icons.delete, size: 20), onPressed: () {
                          setState(() => _projects.remove(p));
                          _saveSettings();
                        }),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            child: showInertiaBreaker 
            ? _buildKernelOverlay(isBlackGate, isKernelCore)
            : _buildMainUI(accentColor, isTactical, isBlackGate, isOperational, isKernel, isKernelCore),
          ),
        ),
      ),
    );
  }

  Widget _buildKernelOverlay(bool isBlackGate, bool isKernelCore) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isBlackGate ? [const Color(0xFF400000), Colors.black] : isKernelCore ? [const Color(0xFF806000), Colors.black] : [const Color(0xFF800000), Colors.black],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isBlackGate ? Icons.warning_amber_rounded : Icons.gavel_rounded, size: 140, color: Colors.white),
          const SizedBox(height: 24),
          Text(
            isBlackGate ? 'ESTADO BLACK GATE' : isKernelCore ? 'BLOQUEO DE INMUTABILIDAD' : 'BLOQUEO DE KERNEL',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            child: Text(
              isBlackGate ? 'ALERTA CRÍTICA: Violación estructural o emergencia detectada.' : isKernelCore ? 'Modificando motor cognitivo (SHS CORE). Acción blindada e irreversible.' : 'Modificando NÚCLEO (FUNDACIÓN). Requiere firma manual exclusiva.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: () => setState(() => _kernelModeActive = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: isBlackGate ? Colors.red.shade900 : isKernelCore ? Colors.amber.shade900 : Colors.red.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 25),
            ),
            child: const Text('INGRESAR AL MODO KERNEL', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildMainUI(Color accentColor, bool isTactical, bool isBlackGate, bool isOperational, bool isKernel, bool isKernelCore) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (isTactical || isBlackGate) const Spacer(flex: 1),
          if (isOperational) const Spacer(flex: 8),
          if (_selectedProject != null) ...[
            _buildBadge(accentColor, isBlackGate, isKernelCore, isKernel, isTactical),
            const SizedBox(height: 24),
          ],
          Hero(tag: 'icon', child: Icon(isBlackGate ? Icons.dangerous_outlined : isKernelCore || isKernel ? Icons.admin_panel_settings : Icons.shield_outlined, size: 100, color: accentColor)),
          const SizedBox(height: 32),
          Text(_status ?? '', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isBlackGate || isKernelCore || isKernel ? accentColor : Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          if (_challenge != null) ...[
            _buildChallengeBox(accentColor, isBlackGate, isKernelCore, isKernel),
            const SizedBox(height: 48),
            _buildActionButtons(isKernel || isKernelCore || isBlackGate, accentColor, isBlackGate, isKernelCore, isKernel, isTactical),
          ],
          if (_lastApprovedId != null) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Text('ÚLTIMA CERTIFICACIÓN PO', style: TextStyle(fontSize: 9, color: Colors.white38, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _lastApprovedLevel == 'BLACK-GATE' ? Colors.red : 
                                 _lastApprovedLevel == 'KERNEL-CORE' ? Colors.amber :
                                 _lastApprovedLevel == 'KERNEL' ? Colors.redAccent :
                                 Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_lastApprovedProjectName ?? ''}: ...${_lastApprovedId!.substring(_lastApprovedId!.length.clamp(8, 999) - 8)}',
                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.verified, size: 14, color: Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          TextButton.icon(onPressed: _sendPanic, icon: const Icon(Icons.warning, color: Colors.red, size: 18), label: const Text('EMERGENCY PANIC (NUKE)', style: TextStyle(color: Colors.red, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildBadge(Color accentColor, bool isBlackGate, bool isKernelCore, bool isKernel, bool isTactical) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), border: Border.all(color: accentColor.withValues(alpha: 0.5)), borderRadius: BorderRadius.circular(20)),
      child: Text(
        isBlackGate ? 'SECURITY LEVEL: GATE-BLACK' : isKernelCore ? 'SECURITY LEVEL: GATE-GOLD' : isKernel ? 'SECURITY LEVEL: KERNEL RED' : isTactical ? 'SECURITY LEVEL: TACTICAL ORANGE' : 'SECURITY LEVEL: OPERATIONAL AMBER',
        style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildChallengeBox(Color accentColor, bool isBlackGate, bool isKernelCore, bool isKernel) {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text('${_selectedProject?.name ?? ''} - ${isBlackGate ? 'CRITICAL' : isKernelCore ? 'GATE-GOLD' : isKernel ? 'KERNEL' : 'TACTICAL'} CHALLENGE', style: const TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text('$_challenge', style: TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.bold, color: accentColor)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool swapped, Color accentColor, bool isBlackGate, bool isKernelCore, bool isKernel, bool isTactical) {
    final authorize = _btn(true, accentColor, isBlackGate, isKernelCore, isKernel, isTactical);
    final reject = _btn(false, accentColor, isBlackGate, isKernelCore, isKernel, isTactical);
    return Column(children: swapped ? [reject, const SizedBox(height: 16), authorize] : [authorize, const SizedBox(height: 16), reject]);
  }

  Widget _btn(bool auth, Color accentColor, bool isBlackGate, bool isKernelCore, bool isKernel, bool isTactical) {
    return SizedBox(
      width: double.infinity,
      height: auth ? 70 : 50,
      child: auth 
        ? ElevatedButton.icon(
            onPressed: _signChallenge,
            icon: const Icon(Icons.fingerprint, size: 30),
            label: Text(isBlackGate ? 'NUCLEAR AUTHORIZE' : isKernelCore ? 'FIRMAR KERNEL-CORE' : isKernel ? 'FIRMAR COMO PO' : 'AUTORIZAR CAMBIO', style: const TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: isBlackGate ? Colors.red.shade900 : isKernelCore ? Colors.amber.shade700 : isKernel ? Colors.red : isTactical ? Colors.orange.shade800 : Colors.green.shade700, foregroundColor: Colors.white),
          )
        : OutlinedButton.icon(
            onPressed: _rejectChallenge,
            icon: const Icon(Icons.do_not_disturb_alt),
            label: const Text('RECHAZAR SOLICITUD'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.grey.shade400, side: const BorderSide(color: Colors.white10)),
          ),
    );
  }
}

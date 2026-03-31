import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../services/governance_service.dart';

class DpiAdoptWizardScreen extends StatefulWidget {
  final GovernanceService? service;
  const DpiAdoptWizardScreen({super.key, this.service});

  @override
  State<DpiAdoptWizardScreen> createState() => _DpiAdoptWizardScreenState();
}

class _DpiAdoptWizardScreenState extends State<DpiAdoptWizardScreen> {
  int _currentStep = 0;
  bool _isScanning = false;
  bool _isAdopting = false;
  String? _errorMessage;
  String? _successMessage;
  
  final _pathController = TextEditingController();
  
  // Scan Results
  Map<String, bool> _checkMap = {
    'VISION.md': false,
    'GEMINI.md': false,
    'vault/rules/roles.json': false,
    'backlog.json': false,
    'task.md': false,
    '.meta/sprints': false,
  };
  int _score = 0;

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _runScan() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _score = 0;
    });

    try {
      final targetPath = _pathController.text.trim();
      final dir = Directory(targetPath);
      
      if (!await dir.exists()) {
        setState(() => _errorMessage = "La ruta no existe.");
        return;
      }

      final service = widget.service ?? GovernanceService();
      final oracleRoot = service.getOracleRoot();
      final result = await service.runGov(
        oracleRoot, 
        ['adopt', targetPath, '--dry-run'],
      );

      if (result.exitCode == 0) {
        final diagData = jsonDecode(result.stdout);
        final List gaps = diagData['gaps'] ?? [];
        
        final checks = {
          'VISION.md': !gaps.contains('TASK-ADOPT-01'),
          'GEMINI.md': !gaps.contains('TASK-ADOPT-02'),
          'vault/rules/roles.json': !gaps.contains('TASK-ADOPT-03'),
          'backlog.json': !gaps.contains('TASK-ADOPT-04'),
          'task.md': !gaps.contains('TASK-ADOPT-04'), // task.md se genera con el backlog
          '.meta/sprints': !gaps.contains('TASK-ADOPT-04'),
        };

        setState(() {
          _checkMap = checks;
          _score = diagData['score'] ?? 0;
          _currentStep = 2;
        });
      } else {
        setState(() => _errorMessage = "Error en el Kernel: ${result.stderr}");
      }
    } catch (e) {
      setState(() => _errorMessage = "Fallo de ejecución: $e");
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _runAdopt() async {
    setState(() {
      _isAdopting = true;
      _errorMessage = null;
    });

    try {
      final targetPath = _pathController.text.trim();
      final service = widget.service ?? GovernanceService();
      final oracleRoot = service.getOracleRoot();
      
      final result = await service.runGov(
        oracleRoot,
        ['adopt', targetPath, '--commit'],
      );

      if (result.exitCode == 0) {
        await service.registerInFleet(
          oracleRoot: oracleRoot,
          projectName: p.basename(targetPath),
          projectPath: targetPath,
        );
        setState(() {
          _successMessage = "Proyecto adoptado y registrado con éxito.";
          _currentStep = 3;
        });
      } else {
        setState(() => _errorMessage = "Fallo en la adopción: ${result.stderr}");
      }
    } catch (e) {
      setState(() => _errorMessage = "Error de sistema: $e");
    } finally {
      if (mounted) setState(() => _isAdopting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Colors.cyanAccent;

    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: accent, size: 28),
              const SizedBox(width: 16),
              const Text("DPI-ADOPT: ADOPTION SPECIALIST", 
                style: TextStyle(color: accent, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 8),
          const Text("Escaneo forense de alineación con el protocolo DPI-GATE-GOLD.", style: TextStyle(color: Colors.white24, fontSize: 12)),
          const SizedBox(height: 40),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(primary: accent),
              ),
              child: Stepper(
                type: StepperType.horizontal,
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep == 0) {
                    if (_pathController.text.isNotEmpty) _runScan();
                  } else if (_currentStep == 2) {
                     setState(() => _currentStep = 0);
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) setState(() => _currentStep = 0);
                },
                controlsBuilder: (context, details) {
                   return Padding(
                     padding: const EdgeInsets.only(top: 32),
                     child: _isScanning ? const CircularProgressIndicator(strokeWidth: 2) : 
                     ElevatedButton(
                       onPressed: details.onStepContinue,
                       style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                       child: Text(_currentStep == 0 ? "INICIAR ESCANEO" : "NUEVO ANÁLISIS"),
                     ),
                   );
                },
                steps: [
                  Step(
                    title: const Text("SELECCIÓN", style: TextStyle(fontSize: 10)),
                    isActive: _currentStep >= 0,
                    content: _buildPathSelector(accent),
                  ),
                  Step(
                    title: const Text("ESCANEO", style: TextStyle(fontSize: 10)),
                    isActive: _currentStep >= 1,
                    content: const Center(child: Text("Analizando estructura de búnkers...", style: TextStyle(color: Colors.white24))),
                  ),
                  Step(
                    title: const Text("RESULTADOS", style: TextStyle(fontSize: 10)),
                    isActive: _currentStep >= 2,
                    content: _buildResults(accent),
                  ),
                  Step(
                    title: const Text("FINALIZADO", style: TextStyle(fontSize: 10)),
                    isActive: _currentStep >= 3,
                    content: _buildSuccess(accent),
                  ),
                ],
              ),
            ),
          ),
          if (_errorMessage != null) _buildAlert(Colors.redAccent, _errorMessage!),
        ],
      ),
    );
  }

  Widget _buildPathSelector(Color accent) {
    return Column(
      children: [
        TextFormField(
          controller: _pathController,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            labelText: "Ruta del Proyecto a Adoptar",
            prefixIcon: Icon(Icons.folder, size: 18, color: accent.withValues(alpha: 0.5)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
          ),
        ),
      ],
    );
  }

  Widget _buildResults(Color accent) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                const Text("DPI ALIGNMENT SCORE", style: TextStyle(color: Colors.white24, fontSize: 8, letterSpacing: 2)),
                const SizedBox(height: 10),
                Text("$_score%", style: TextStyle(color: accent, fontSize: 48, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text("BRECHAS DE GOBERNANZA DETECTADAS", style: TextStyle(color: Colors.white24, fontSize: 8, letterSpacing: 1.5)),
        ),
        const SizedBox(height: 16),
        ...(_checkMap.entries.toList()..sort((a, b) => a.value ? 1 : -1))
            .map((e) => _checkLine(e.key, e.value, accent)),
        const SizedBox(height: 40),
        if (_currentStep == 2)
          ElevatedButton(
            onPressed: _isAdopting ? null : _runAdopt,
            style: ElevatedButton.styleFrom(
              backgroundColor: _score >= 60 ? Colors.orangeAccent : Colors.redAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            ),
            child: Text(_isAdopting ? "ADOPTANDO..." : "ADOPTAR PROYECTO (--commit)"),
          ),
      ],
    );
  }

  Widget _buildSuccess(Color accent) {
    return Column(
      children: [
        const Icon(Icons.check_circle, color: Colors.greenAccent, size: 60),
        const SizedBox(height: 20),
        Text(_successMessage ?? "Adopción completada.", style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => setState(() => _currentStep = 0),
          child: const Text("VOLVER AL INICIO"),
        ),
      ],
    );
  }

  Widget _checkLine(String label, bool found, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(found ? Icons.check_circle : Icons.cancel, color: found ? accent : Colors.redAccent, size: 16),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: found ? Colors.white70 : Colors.white24, fontSize: 12)),
          const Spacer(),
          Text(found ? "DETECTADO" : "FALTA", style: TextStyle(fontSize: 9, color: found ? accent.withValues(alpha: 0.5) : Colors.redAccent.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildAlert(Color color, String msg) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), border: Border.all(color: color.withValues(alpha: 0.5)), borderRadius: BorderRadius.circular(4)),
      child: Row(children: [Icon(Icons.info_outline, size: 16, color: color), const SizedBox(width: 12), Expanded(child: Text(msg, style: TextStyle(color: color, fontSize: 12)))]),
    );
  }
}

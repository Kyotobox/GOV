import 'package:flutter/material.dart';
import '../../services/governance_service.dart';

class DpiInitWizardScreen extends StatefulWidget {
  final GovernanceService? service;
  const DpiInitWizardScreen({super.key, this.service});

  @override
  State<DpiInitWizardScreen> createState() => _DpiInitWizardScreenState();
}

class _DpiInitWizardScreenState extends State<DpiInitWizardScreen> {
  int _currentStep = 0;
  bool _isExecuting = false;
  String? _errorMessage;
  String? _successMessage;

  final _nameController = TextEditingController();
  final _pathController = TextEditingController();
  final _visionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    _visionController.dispose();
    super.dispose();
  }

  Future<void> _runInit() async {
    setState(() {
      _isExecuting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final projectName = _nameController.text.trim();
      final targetPath = _pathController.text.trim();
      
      final service = widget.service ?? GovernanceService();
      final oracleRoot = service.getOracleRoot();
      
      final result = await service.runGov(
        oracleRoot, 
        ['init', targetPath, '--name', projectName, '--vision', _visionController.text.trim()],
      );

      if (result.exitCode == 0) {
        // [S25-05] Registrar en la flota
        await service.registerInFleet(
          oracleRoot: oracleRoot,
          projectName: projectName,
          projectPath: targetPath,
        );
        setState(() => _successMessage = "Búnker '$projectName' instanciado y registrado en la flota.");
      } else {
        setState(() => _errorMessage = "Error en el Kernel: ${result.stderr}");
      }
    } catch (e) {
      setState(() => _errorMessage = "Fallo de ejecución: $e");
    } finally {
      if (mounted) setState(() => _isExecuting = false);
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
              const Icon(Icons.add_moderator, color: accent, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Text("DPI-INIT: WIZARD DE INICIACIÓN", 
                  style: TextStyle(color: accent, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text("Instanciación de nuevos proyectos bajo el protocolo DPI-GATE-GOLD.", style: TextStyle(color: Colors.white24, fontSize: 12)),
          const SizedBox(height: 40),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(primary: accent, secondary: accent),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Stepper(
                  type: StepperType.horizontal,
                  currentStep: _currentStep,
                  onStepContinue: () {
                    if (_currentStep < 2) {
                      bool isValid = false;
                      if (_currentStep == 0) {
                        isValid = _nameController.text.trim().isNotEmpty && _pathController.text.trim().isNotEmpty;
                        if (!isValid) {
                          setState(() => _errorMessage = "Identidad Incompleta");
                        } else {
                          setState(() => _errorMessage = null);
                        }
                      } else if (_currentStep == 1) {
                        isValid = _visionController.text.trim().isNotEmpty;
                        if (!isValid) {
                          setState(() => _errorMessage = "Visión Incompleta");
                        } else {
                          setState(() => _errorMessage = null);
                        }
                      }
                      
                      if (isValid) {
                        setState(() => _currentStep++);
                      }
                    } else {
                      _runInit();
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) setState(() => _currentStep--);
                  },
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Row(
                        children: [
                          if (_isExecuting)
                            const CircularProgressIndicator(strokeWidth: 2)
                          else ...[
                            ElevatedButton(
                              key: Key('wizard_next_step_${details.stepIndex}'),
                              onPressed: details.onStepContinue,
                              style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                              child: Text(_currentStep == 2 ? "INICIAR BÚNKER" : "CONTINUAR"),
                            ),
                            if (_currentStep > 0)
                              TextButton(
                                onPressed: details.onStepCancel,
                                child: const Text("ATRÁS", style: TextStyle(color: Colors.white24)),
                              ),
                          ]
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: const Text("IDENTIDAD", style: TextStyle(fontSize: 10)),
                      isActive: _currentStep >= 0,
                      content: Column(
                        children: [
                          _buildTextField(_nameController, "Nombre del Proyecto", "Ej: Alpha-Project", Icons.label_important, key: const Key('dpi_init_name')),
                          const SizedBox(height: 20),
                          _buildTextField(_pathController, "Ruta Destino Absoluta", "C:\\Users\\...\\ProjectX", Icons.folder, isPath: true, key: const Key('dpi_init_path')),
                        ],
                      ),
                    ),
                    Step(
                      title: const Text("VISIÓN", style: TextStyle(fontSize: 10)),
                      isActive: _currentStep >= 1,
                      content: _buildTextField(_visionController, "Visión del Producto (SSoT)", "Escribe los objetivos estratégicos...", Icons.visibility, maxLines: 5, key: const Key('dpi_init_vision')),
                    ),
                    Step(
                      title: const Text("CONFIRMACIÓN", style: TextStyle(fontSize: 10)),
                      isActive: _currentStep >= 2,
                      content: _buildSummary(accent),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_errorMessage != null) _buildAlert(Colors.redAccent, _errorMessage!),
          if (_successMessage != null) _buildAlert(accent, _successMessage!),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon, {int maxLines = 1, bool isPath = false, Key? key}) {
    return TextFormField(
      key: key,
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: Colors.cyanAccent.withValues(alpha: 0.5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
      ),
      validator: (value) => (value == null || value.isEmpty) ? "Campo requerido" : null,
    );
  }

  Widget _buildSummary(Color accent) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: accent.withValues(alpha: 0.05), border: Border.all(color: accent.withValues(alpha: 0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryLine("PROYECTO", _nameController.text),
          _summaryLine("DESTINO", _pathController.text),
          const Divider(color: Colors.white10, height: 32),
          const Text("VISIÓN ESTRATÉGICA", style: TextStyle(color: Colors.white24, fontSize: 8, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(_visionController.text, style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.5)),
        ],
      ),
    );
  }

  Widget _summaryLine(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text("$k: ", style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
          Text(v, style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanguard_agent/features/dpi_init/dpi_init_wizard_screen.dart';
import 'package:vanguard_agent/services/governance_service.dart';
import 'dart:io';

/// Mock manual del servicio de gobernanza
class MockGovernanceService extends GovernanceService {
  bool called = false;
  List<String>? lastArgs;
  int exitCodeToReturn = 0;

  @override
  Future<ProcessResult> runGov(String rootPath, List<String> args) async {
    called = true;
    lastArgs = args;
    return ProcessResult(0, exitCodeToReturn, '', '');
  }
}

void main() {
  testWidgets('SIMULACIÓN: Flujo completo del Wizard DPI-INIT', (WidgetTester tester) async {
    final mockService = MockGovernanceService();

    // 1. Cargar el Wizard con el Mock inyectado
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: DpiInitWizardScreen(service: mockService)),
    ));
    await tester.pumpAndSettle();

    // Verificar Paso 1: Identidad
    expect(find.text('DPI-INIT: WIZARD DE INICIACIÓN'), findsOneWidget);
    
    await tester.enterText(find.byKey(const Key('dpi_init_name')), 'Bunker-Alpha');
    await tester.enterText(find.byKey(const Key('dpi_init_path')), 'C:\\Projects\\Alpha');
    await tester.pump(); // Sincronizar controladores
    
    await tester.tap(find.byKey(const Key('wizard_next_step_0')));
    await tester.pumpAndSettle();

    // Verificar Paso 2: Visión
    expect(find.byKey(const Key('dpi_init_vision')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('dpi_init_vision')), 'Proteger la semilla del código.');
    await tester.pump(); // Sincronizar controlador
    
    final step1Button = find.byKey(const Key('wizard_next_step_1'));
    await tester.ensureVisible(step1Button);
    await tester.tap(step1Button);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500)); // Margen para animaciones del Stepper

    // Verificar Paso 3: Confirmación
    expect(find.text('CONFIRMACIÓN'), findsOneWidget);
    expect(find.text('Bunker-Alpha'), findsOneWidget);
    
    // 2. Ejecutar Iniciación (Botón final de paso 2)
    final step2Button = find.byKey(const Key('wizard_next_step_2'));
    await tester.ensureVisible(step2Button);
    await tester.tap(step2Button);
    await tester.pump(); // Iniciar animación/futuro

    // 3. Validar Interacción con el Kernel (Mock)
    expect(mockService.called, isTrue);
    expect(mockService.lastArgs, contains('Bunker-Alpha'));
    expect(mockService.lastArgs, contains('init'));
  });
}

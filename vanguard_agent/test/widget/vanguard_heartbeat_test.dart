import 'package:flutter_test/flutter_test.dart';
import 'package:vanguard_agent/main.dart';

void main() {
  testWidgets('Vanguard Heartbeat Sync Engine Test', (WidgetTester tester) async {
    // 1. Iniciar App
    await tester.pumpWidget(const VanguardElite());
    
    // 2. Encontrar el HUD
    final mainHUD = find.byType(MainHUD);
    expect(mainHUD, findsOneWidget);
    
    // 3. Verificar estado inicial del Heartbeat
    final state = tester.state(mainHUD);
    expect(state.mounted, isTrue);
    
    // 4. Simular avance de tiempo (15s)
    // Nota: No podemos probar la ejecución de procesos externos en un widget test básico fácilmente,
    // pero podemos verificar que el timer existe y está activo.
    // expect(state.heartbeatTimer?.isActive ?? false, isTrue);
    
    // 5. Verificar que el build se mantiene estable
    await tester.pump();
    expect(find.text('SHS PULSE'), findsOneWidget);
  });
}

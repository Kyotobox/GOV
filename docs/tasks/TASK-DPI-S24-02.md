# TASK-DPI-S24-02: Fricción Visual BLACK-GATE en Vanguard (Flutter)

## Metadatos
- **Sprint**: S24-BLACKGATE
- **Label**: UI
- **Gate**: STRATEGIC-GOLD
- **Dependencias**: TASK-DPI-S24-01, TASK-DPI-S23-02 completadas
- **Archivos en Scope**: `vanguard_agent/lib/main.dart`

## Objetivo
Implementar los tres mecanismos de fricción sensorial cuando el nivel es `BLACK-GATE`:
1. **Fondo negro con pulso rojo** (animación de destello).
2. **Alarma sonora** (5 beeps rápidos).
3. **Posición aleatoria** del botón de firma.

## Pre-flight Check
El código actual en `main.dart` ya tiene el fondo negro para `BLACK-GATE`. Verificar que existe y ajustar.

## Pasos de Ejecución

### Paso 1: Añadir animación de pulso rojo
En la clase `_AgentHomeState`, añadir un `AnimationController` para el pulso:

```dart
late AnimationController _pulseController;
late Animation<double> _pulseAnimation;

@override
void initState() {
  super.initState();
  _loadSettings();
  _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..repeat(reverse: true);
  _pulseAnimation = Tween<double>(begin: 0.0, end: 0.3).animate(_pulseController);
}

@override
void dispose() {
  _subscription?.cancel();
  _pulseController.dispose();
  super.dispose();
}
```

Añadir `with SingleTickerProviderStateMixin` a la definición de la clase:
```dart
class _AgentHomeState extends State<AgentHome> with SingleTickerProviderStateMixin {
```

### Paso 2: Aplicar la animación en el fondo BLACK-GATE
En el método `build`, cuando `isBlackGate == true`, envolver el `Scaffold` en un `AnimatedBuilder`:

```dart
@override
Widget build(BuildContext context) {
  // ... (código existente de variables isBlackGate, bgColor, etc.)
  
  Widget scaffold = Theme(
    data: ThemeData.dark().copyWith(/* ... */),
    child: Scaffold(/* ... */),
  );
  
  if (isBlackGate) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.red.withValues(alpha: _pulseAnimation.value),
                ),
              ),
            ),
          ],
        );
      },
      child: scaffold,
    );
  }
  
  return scaffold;
}
```

### Paso 3: Aleatorizar la posición de los botones para BLACK-GATE
En el método `_buildActionButtons`, cuando el nivel es `BLACK-GATE`, randomizar el orden:

```dart
Widget _buildActionButtons(bool swapped, Color accentColor, bool isBlackGate, ...) {
  final authorize = _btn(true, accentColor, isBlackGate, isKernelCore, isKernel, isTactical);
  final reject = _btn(false, accentColor, isBlackGate, isKernelCore, isKernel, isTactical);
  
  // Para BLACK-GATE: posición verdaderamente aleatoria en cada render
  bool randomOrder = swapped;
  if (isBlackGate) {
    randomOrder = DateTime.now().millisecondsSinceEpoch % 2 == 0;
  }
  
  return Column(
    children: randomOrder 
      ? [reject, const SizedBox(height: 16), authorize]
      : [authorize, const SizedBox(height: 16), reject],
  );
}
```

### Paso 4: Verificar que la alarma sonora ya está implementada
El método `_playLevelAlarm` ya existe. Confirmar que para `BLACK-GATE` emite 5 beeps con `SystemSound.alert`. Si no está, añadirlo (ver TASK-DPI-S23-03).

### Paso 5: flutter analyze
```powershell
cd vanguard_agent
flutter analyze
```
0 errores.

## Criterio de Éxito
- Con un desafío de nivel `BLACK-GATE`, el agente muestra pulso rojo animado.
- Los botones cambian de posición entre renders.
- La alarma sonora suena 5 veces.
- `flutter analyze` → 0 errores.

## Criterio de Fallo (DETENER si ocurre)
- El fondo no tiene animación de pulso.
- Los botones siempre están en la misma posición.
- `flutter analyze` reporta errores.

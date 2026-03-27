# TASK-DPI-S21-02: Hardcode de Reglas SHS como Constantes Inmutables

## Metadatos
- **Sprint**: S21-RESTORE
- **Label**: SEC
- **Gate**: OPERATIONAL-RED
- **Dependencias**: TASK-DPI-S21-01 completada
- **Archivos en Scope**: `bin/antigravity_dpi.dart`, `test/` (nuevo test)

## Objetivo
Las reglas de Saturación (SHS) deben ser inmutables. El límite de archivos en raíz y la penalización por zombie NO pueden ser alterados por la IA ni por ningún operador sin pasar por BLACK-GATE. Se deben convertir a `static const` y verificarse con un test unitario.

## Pre-flight Check
```powershell
dart test
```
Todos los tests existentes deben pasar antes de iniciar.

## Pasos de Ejecución

### Paso 1: Definir constantes en `IntegrityEngine`
En `bin/antigravity_dpi.dart`, dentro de la clase `IntegrityEngine`, agregar al inicio de la clase:

```dart
class IntegrityEngine {
  // REGLAS DURAS — No modificar sin nivel BLACK-GATE + firma RSA del PO
  static const int kMaxRootFiles = 15;
  static const double kZombiePenalty = 20.0;
  static const double kPanicThreshold = 90.0;
  
  // ... resto de la clase
}
```

### Paso 2: Usar las constantes en el cálculo de SHS
En el método `_runAudit` (o donde se calcula la saturación), reemplazar valores numéricos literales por las constantes:

```dart
// ANTES (literal):
double saturation = (swelling.fileCount / 15.0) * 100;
if (zombies.isNotEmpty) saturation += (zombies.length * 20.0);

// DESPUÉS (constantes):
double saturation = (swelling.fileCount / IntegrityEngine.kMaxRootFiles) * 100;
if (zombies.isNotEmpty) saturation += (zombies.length * IntegrityEngine.kZombiePenalty);
```

### Paso 3: Implementar Auto-Lock en `_runBaseline`
Al inicio de `_runBaseline`, antes de emitir el desafío:

```dart
Future<void> _runBaseline(String basePath, String message) async {
  // AUTO-LOCK: Verificar SHS antes de permitir el sellado
  final integrity = IntegrityEngine();
  final swelling = await integrity.checkSwelling(basePath);
  final zombies = await integrity.checkZombies(basePath);
  double saturation = (swelling.fileCount / IntegrityEngine.kMaxRootFiles) * 100;
  if (zombies.isNotEmpty) saturation += (zombies.length * IntegrityEngine.kZombiePenalty);
  
  if (saturation >= IntegrityEngine.kPanicThreshold) {
    print('[BLOCKED] SHS en estado PANIC (${saturation.toStringAsFixed(1)}%). Purga requerida antes de sellar.');
    exit(1);
  }
  // ... resto del método
}
```

### Paso 4: Crear test unitario en `test/`
Crear el archivo `test/shs_rules_test.dart`:

```dart
import 'package:test/test.dart';

// Importar desde bin o lib según estructura.
// Este test verifica que las constantes no han sido alteradas.
void main() {
  group('SHS Hard Rules (Inmutables)', () {
    test('kMaxRootFiles debe ser exactamente 15', () {
      expect(IntegrityEngine.kMaxRootFiles, equals(15));
    });
    
    test('kZombiePenalty debe ser exactamente 20.0', () {
      expect(IntegrityEngine.kZombiePenalty, equals(20.0));
    });
    
    test('kPanicThreshold debe ser exactamente 90.0', () {
      expect(IntegrityEngine.kPanicThreshold, equals(90.0));
    });
    
    test('1 zombie en sistema de 5 archivos resulta en saturación > 90%', () {
      double saturation = (5 / IntegrityEngine.kMaxRootFiles) * 100;
      saturation += (1 * IntegrityEngine.kZombiePenalty);
      expect(saturation, greaterThan(IntegrityEngine.kPanicThreshold));
    });
  });
}
```

## Criterio de Éxito
- `dart analyze` → 0 errores.
- `dart test test/shs_rules_test.dart` → 4/4 tests en verde.
- `dart bin/antigravity_dpi.dart audit` → Muestra las métricas usando las constantes.
- Un intento de `baseline` con SHS > 90% es bloqueado con mensaje `[BLOCKED]`.

## Criterio de Fallo (DETENER si ocurre)
- Los valores numéricos `15`, `20.0` o `90.0` permanecen como literales en el código de cálculo.
- `dart test` falla.

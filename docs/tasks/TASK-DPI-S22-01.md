# TASK-DPI-S22-01: Ledger Chain of Trust (Encadenamiento de Hashes)

## Metadatos
- **Sprint**: S22-LEDGER
- **Label**: GOV
- **Gate**: OPERATIONAL-RED
- **Dependencias**: S21 completado
- **Archivos en Scope**: `lib/src/telemetry/forensic_ledger.dart`, `test/`

## Objetivo
El `ForensicLedger` actual registra eventos pero no los encadena. Cada entrada debe incluir el SHA-256 de la entrada anterior, formando una cadena inmutable. Si alguien borra o modifica una entrada, `gov audit` detecta la ruptura de cadena y entra en PANIC.

## Pre-flight Check
```powershell
dart test
```
Todos los tests existentes deben pasar.

## Pasos de Ejecución

### Paso 1: Revisar el archivo actual
Leer `lib/src/telemetry/forensic_ledger.dart` completo para entender la estructura actual de cada entrada del ledger.

### Paso 2: Añadir campo `previousHash` a cada entrada
En la función que escribe una nueva entrada al ledger, antes de guardarla:

```dart
// Al escribir una nueva entrada, incluir el hash de la entrada anterior:
Future<void> logEvent(String event, String details) async {
  final ledgerFile = File(_ledgerPath); // ruta al archivo de ledger
  
  // 1. Leer el hash de la última entrada (o '0' * 64 si es la primera)
  String previousHash = '0' * 64;
  if (await ledgerFile.exists()) {
    final lines = await ledgerFile.readAsLines();
    if (lines.isNotEmpty) {
      final lastLine = lines.last;
      // Extraer el hash de la última línea (adaptar al formato actual)
      final lastHash = sha256.convert(utf8.encode(lastLine)).toString();
      previousHash = lastHash;
    }
  }
  
  // 2. Construir la nueva entrada con el encadenamiento
  final entry = {
    'timestamp': DateTime.now().toIso8601String(),
    'event': event,
    'details': details,
    'previousHash': previousHash,
  };
  
  final entryJson = jsonEncode(entry);
  await ledgerFile.writeAsString('$entryJson\n', mode: FileMode.append);
}
```

### Paso 3: Implementar verificación de cadena en `gov audit`
Agregar una función `_verifyLedgerChain` que recorra todas las entradas y verifique la cadena:

```dart
Future<bool> _verifyLedgerChain(String ledgerPath) async {
  final file = File(ledgerPath);
  if (!file.existsSync()) return true; // Ledger vacío es válido
  
  final lines = await file.readAsLines();
  if (lines.isEmpty) return true;
  
  String expectedPreviousHash = '0' * 64;
  
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    
    try {
      final entry = jsonDecode(line);
      final recordedPrevious = entry['previousHash'] as String? ?? '';
      
      if (recordedPrevious != expectedPreviousHash) {
        print('[CHAIN BROKEN] Entrada $i: hash previo no coincide.');
        return false;
      }
      
      // El hash de esta entrada será el "previousHash" de la siguiente
      expectedPreviousHash = sha256.convert(utf8.encode(line)).toString();
    } catch (e) {
      print('[CHAIN BROKEN] Entrada $i: JSON inválido.');
      return false;
    }
  }
  
  return true;
}
```

### Paso 4: Invocar verificación en `_runAudit`
Al final del método `_runAudit`, agregar:

```dart
final ledgerPath = p.join(basePath, 'HISTORY.md'); // Ajustar a la ruta real del ledger
final isChainValid = await _verifyLedgerChain(ledgerPath);
if (!isChainValid) {
  print('[CRITICAL] LEDGER CHAIN BROKEN: Posible tampering detectado. PANIC MODE.');
}
```

### Paso 5: Crear test unitario
Crear `test/ledger_chain_test.dart`:

```dart
import 'package:test/test.dart';
import 'dart:io';

void main() {
  group('Ledger Chain of Trust', () {
    test('Cadena válida pasa verificación', () async {
      // Crear un ledger temporal con entradas encadenadas correctamente
      // Verificar que _verifyLedgerChain retorna true
    });
    
    test('Cadena rota falla verificación', () async {
      // Crear un ledger temporal y alterar una entrada a mano
      // Verificar que _verifyLedgerChain retorna false
    });
  });
}
```

## Criterio de Éxito
- `dart test test/ledger_chain_test.dart` → verde.
- `gov audit` detecta y reporta ruptura de cadena si se altera el ledger manualmente.
- Cada nueva entrada del ledger tiene el campo `previousHash`.

## Criterio de Fallo (DETENER si ocurre)
- El ledger puede ser alterado sin que `audit` lo detecte.
- Los tests fallan.

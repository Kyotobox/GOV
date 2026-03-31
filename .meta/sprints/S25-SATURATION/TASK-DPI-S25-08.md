# TASK-DPI-S25-08: Fecha del Último Git Push en Panel de Telemetría

## Contexto
El panel de telemetría lateral de Vanguard (sección "ESTADO DE NÚCLEO") muestra
información estática sobre el proyecto. Sería valioso mostrar la fecha del último
push al repositorio remoto para tener visibilidad del estado de sincronización con el origen.

Esto ayuda a detectar si el motor lleva más de 24h sin ser pusheado, lo que indicaría
que hay commits locales pendientes de subir.

## Archivos a Modificar
- `vanguard_agent/lib/main.dart` — añadir `_lastPushDate`
- `vanguard_agent/lib/screens/terminal_tab.dart` — mostrar en `_buildTelemetryPanel()`

## Implementación Paso a Paso

### Paso 1 — Variable de estado en `_MainHUDState`

```dart
String _lastPushDate = '---'; // [S25-08]
bool _pushIsStale = false;    // [S25-08] true si el último push es > 24h
```

### Paso 2 — Función para obtener la fecha del último push

En `_MainHUDState`, agregar:

```dart
Future<void> _loadLastPushDate(String rootPath) async {
  try {
    // git log --remotes -1 --format=%ai devuelve la fecha del último commit remoto
    final result = await Process.run(
      'git',
      ['log', '--remotes', '-1', '--format=%ai'],
      workingDirectory: rootPath,
      runInShell: true,
    );
    if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
      final rawDate = result.stdout.toString().trim();
      // Formato ISO: 2026-03-30 06:37:15 -0400
      final dt = DateTime.parse(rawDate.replaceFirst(' ', 'T').split(' ').take(2).join(''));
      final diff = DateTime.now().difference(dt);
      final String formatted = '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
      if (mounted) setState(() {
        _lastPushDate = formatted;
        _pushIsStale = diff.inHours > 24; // [S25-08] Warning si > 24h
      });
    } else {
      if (mounted) setState(() => _lastPushDate = 'SIN REMOTE');
    }
  } catch (_) {
    if (mounted) setState(() => _lastPushDate = 'NO GIT');
  }
}
```

### Paso 3 — Llamar `_loadLastPushDate` en `_refreshTelemetry()`

Al final de `_refreshTelemetry()`, después de cargar el backlog:

```dart
// [S25-08] Cargar fecha del último push
if (_selectedProject != null) {
  _loadLastPushDate(_selectedProject!.rootPath);
}
```

> Se llama sin `await` para no bloquear la actualización del HUD.

### Paso 4 — Pasar `lastPushDate` y `pushIsStale` a `TerminalTab`

En `TerminalTab`, añadir parámetros:
```dart
final String lastPushDate;
final bool pushIsStale;
```

En `main.dart`, pasar los valores:
```dart
case 0: return TerminalTab(
  // parámetros existentes...
  lastPushDate: _lastPushDate,       // [S25-08]
  pushIsStale: _pushIsStale,         // [S25-08]
);
```

### Paso 5 — Mostrar en `_buildTelemetryPanel()`

En `terminal_tab.dart`, en el método `_buildTelemetryPanel()`:

```dart
Widget _buildTelemetryPanel() {
  return Container(
    // ... container existente sin cambios ...
    child: Column(
      children: [
        // ... kvLines existentes ...
        const Divider(color: Colors.white10),
        Tooltip(
          message: 'Fecha y hora del último commit pusheado al repositorio remoto.\n'
              'Si es > 24h, considera hacer push para sincronizar el Motor.',
          child: _kvLine(
            'ÚLTIMO PUSH',
            lastPushDate,
            // [S25-08] Color naranja si el push es > 24h
            color: pushIsStale ? Colors.orangeAccent : null,
          ),
        ),
      ],
    ),
  );
}
```

> Nota: `_kvLine` actualmente no acepta `color` como parámetro. Agregar un parámetro
> opcional `Color? color` a la función para soportar este caso.

### Modificación de `_kvLine` para soportar color opcional

```dart
Widget _kvLine(String k, String v, {bool small = false, Color? color}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: TextStyle(fontSize: small ? 7 : 8, color: Colors.white24)),
        Text(v, style: TextStyle(
          fontSize: small ? 9 : 10,
          fontWeight: FontWeight.bold,
          color: color ?? accent, // [S25-08] Usar color override si se provee
        )),
      ],
    ),
  );
}
```

## Criterios de Aceptación
- [ ] El panel lateral de Vanguard muestra "ÚLTIMO PUSH" con la fecha del último commit remoto
- [ ] Si el último push tiene más de 24h, el valor se muestra en color naranja (`orangeAccent`)
- [ ] Si el proyecto no tiene repositorio git, muestra "NO GIT" sin errores
- [ ] Si no hay commits remotos (repo sin push nunca), muestra "SIN REMOTE"
- [ ] La fecha se actualiza cada vez que se refresca la telemetría (cada 15s)

## Restricciones (NO HACER)
- NO usar `git fetch` automáticamente — solo `git log --remotes` que usa el cache local
- NO bloquear el HUD esperando por el proceso git — usar sin `await` en `_refreshTelemetry`
- NO mostrar la hora en UTC — usar la hora local del sistema

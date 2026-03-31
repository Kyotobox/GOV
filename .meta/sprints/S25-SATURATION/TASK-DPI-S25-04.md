# TASK-DPI-S25-04: Mejoras UX al Botón Emergency Handover

## Contexto
El botón de Emergency Handover YA EXISTE y funciona correctamente (sidebar nav, línea 488 de main.dart).
Ya tiene dos modos: SELLAR (handover normal) y FORZAR (handover --force).

Esta tarea mejora la experiencia de usuario con:
1. Modal de confirmación para FORZAR con descripción de consecuencias
2. Estado visual post-handover en el HUD (dot gris + label "SEALED")

## Archivos a Modificar
- `vanguard_agent/lib/main.dart`

## Estado Actual del Botón (NO TOCAR la lógica base)

```dart
// Línea 488 — en _buildSidebar()
Padding(padding: const EdgeInsets.only(bottom: 24), child: _buildEmergencyHandoverButton(color)),
```

El método `_buildEmergencyHandoverButton()` muestra:
- Botón de power → `_confirmingHandover = true`
- Modo confirmación: dos íconos (SELLAR + FORZAR) + CANCELAR

## Implementación Paso a Paso

### Paso 1 — Añadir variable de estado _isSealed

En `_MainHUDState`, agregar:
```dart
bool _isSealed = false; // [S25-04] Estado post-handover
```

### Paso 2 — Actualizar `_runHandover()` y `_runForcedHandover()` para activar _isSealed

```dart
Future<void> _runHandover() async {
  // ... código existente ...
  if (mounted) setState(() {
    _confirmingHandover = false;
    _isSealed = true; // [S25-04]
  });
  _refreshTelemetry(_selectedProject!);
}

Future<void> _runForcedHandover() async {
  // ... código existente ...
  if (mounted) setState(() {
    _confirmingHandover = false;
    _isSealed = true; // [S25-04]
  });
  _refreshTelemetry(_selectedProject!);
}
```

### Paso 3 — Indicador visual SEALED en el header

En `_buildHeader()`, el primer elemento es el dot de color. Modificar para que cuando `_isSealed`:
```dart
Container(
  width: 14, height: 14,
  decoration: BoxDecoration(
    color: _isSealed ? Colors.grey : color,  // [S25-04] Gris si sellado
    shape: BoxShape.circle,
    boxShadow: [BoxShadow(color: (_isSealed ? Colors.grey : color).withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)]
  )
),
// [S25-04] Label SEALED
if (_isSealed) ...[
  const SizedBox(width: 8),
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(3), border: Border.all(color: Colors.grey.withValues(alpha: 0.3))),
    child: const Text('SEALED', style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
  ),
],
```

### Paso 4 — Modal de confirmación para FORZAR

Reemplazar el InkWell de "FORZAR" en `_buildConfirmationIcon` por:

```dart
// Para el botón FORZAR — usar showDialog en vez de ejecución directa
InkWell(
  onTap: () async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF000508),
        shape: RoundedRectangleBorder(side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3))),
        title: const Text('HANDOVER FORZADO', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
        content: const Text(
          '⚠️ El handover forzado sella la sesión sin verificación de integridad.\n\n'
          'Consecuencias:\n'
          '• Se omite la firma RSA del sello\n'
          '• La fatiga acumulada se pierde sin registro\n'
          '• El próximo takeover comenzará sin historial\n\n'
          'Usar solo si el handover normal falla.',
          style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.6),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR', style: TextStyle(color: Colors.white38))),
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
  // ... child widget del ícono de FORZAR, sin cambios
)
```

### Paso 5 — Reset de _isSealed al cambiar de proyecto

En `_selectProject()`, agregar:
```dart
setState(() {
  _selectedProject = project;
  _isSealed = false; // [S25-04] Nuevo proyecto, resetear estado SEALED
  // ... resto de reseteos existentes
});
```

## Criterios de Aceptación
- [ ] Clic en botón de Handover Normal → ejecuta sin modal, HUD muestra dot gris + label "SEALED"
- [ ] Clic en FORZAR → muestra modal de confirmación con descripción de consecuencias
- [ ] Clic en CANCELAR en el modal → no ejecuta nada
- [ ] Cambiar de proyecto → el estado "SEALED" desaparece
- [ ] La lógica de `_runHandover()` y `_runForcedHandover()` permanece sin cambios funcionales

## Restricciones (NO HACER)
- NO modificar la lógica de `runHandover` en gov.dart — solo cambios en la UI de Vanguard
- NO mover el botón de lugar — permanece en el bottom del sidebar

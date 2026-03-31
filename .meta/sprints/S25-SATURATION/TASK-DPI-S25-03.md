# TASK-DPI-S25-03: Dual Dial Minimalista en Vanguard

## Contexto
Actualmente Vanguard muestra un solo indicador (`TacticalRadarRing`) que funde BHI y CUS en un único
valor de saturación genérico. El estado real del núcleo son DOS dominios independientes:

- **BHI (Bunker Health Index)**: Salud estructural del búnker. Sube cuando hay zombies, archivos huérfanos
  o código de alta densidad. Se reduce con `gov housekeeping`.
- **CUS (Context Utilization Score)**: Fatiga cognitiva del modelo LLM. Sube con cada `gov act` y
  `gov baseline`. Se resetea SOLO con `gov handover`.

El nuevo diseño es **minimalista**: dos arcos de progreso lado a lado con label + porcentaje.

## Archivos a Modificar
1. `vanguard_agent/lib/screens/terminal_tab.dart` — reemplazar `TacticalRadarRing` por `DualGaugePanel`
2. `vanguard_agent/lib/main.dart` — pasar `_cus` y `_bhi` a `TerminalTab`

## Diseño del Dual Dial

### Layout Visual (minimalista)
```
    ╔════════════════════════════════╗
    ║   [Arc]  BHI    [Arc]  CUS    ║
    ║    20%  BÚNKER   0%  CONTEXTO ║
    ║              [TASK-ID]         ║
    ╚════════════════════════════════╝
```

- Cada dial: `SizedBox(180x180)` con `CustomPaint` de arco de 270°
- BHI: color `Colors.greenAccent → Colors.orangeAccent → Colors.redAccent` según valor
- CUS: color `Colors.cyanAccent → Colors.orangeAccent → Colors.redAccent` según valor
- Task ID activa centrada debajo de ambos diales

## Implementación Paso a Paso

### Paso 1 — Modificar `TerminalTab` para recibir `cus` y `bhi`

En `terminal_tab.dart`, añadir al constructor:
```dart
class TerminalTab extends StatelessWidget {
  final double cus;   // [S25-03] NUEVO
  final double bhi;   // [S25-03] NUEVO
  // ... resto de parámetros existentes sin cambios
```

### Paso 2 — Crear el widget `DualGaugePanel`

Agregar al final de `terminal_tab.dart`:

```dart
class DualGaugePanel extends StatelessWidget {
  final double bhi;
  final double cus;
  final Color accent;
  final String activeTaskId;

  const DualGaugePanel({
    super.key,
    required this.bhi,
    required this.cus,
    required this.accent,
    required this.activeTaskId,
  });

  Color _colorFor(double value, {required bool isBhi}) {
    if (value < 0.5) return isBhi ? Colors.greenAccent : Colors.cyanAccent;
    if (value < 0.75) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGauge('BHI', 'BÚNKER', bhi, _colorFor(bhi, isBhi: true)),
            const SizedBox(width: 48),
            _buildGauge('CUS', 'CONTEXTO', cus, _colorFor(cus, isBhi: false)),
          ],
        ),
        const SizedBox(height: 16),
        Tooltip(
          message: 'ID de la tarea activa en el backlog de gobernanza.',
          child: Text(
            activeTaskId,
            style: TextStyle(
              color: accent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGauge(String label, String subtitle, double value, Color color) {
    return Tooltip(
      message: label == 'BHI'
          ? 'Bunker Health Index: Salud estructural del búnker.\nSube con zombies y deuda técnica. Se reduce con housekeeping.'
          : 'Context Utilization Score: Fatiga cognitiva del modelo.\nSube con cada act/baseline. Se resetea con handover.',
      child: SizedBox(
        width: 140, height: 140,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(140, 140),
              painter: _ArcGaugePainter(value: value, color: color),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 9, letterSpacing: 3)),
                const SizedBox(height: 4),
                Text('${(value * 100).toInt()}%', style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -2)),
                Text(subtitle, style: TextStyle(color: color.withValues(alpha: 0.3), fontSize: 7, letterSpacing: 1.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  final double value;
  final Color color;
  const _ArcGaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const startAngle = 2.36; // -135 degrees
    const sweepMax = 4.71;   // 270 degrees
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    // Background arc
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepMax, false, bgPaint);
    // Foreground arc (filled)
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepMax * value.clamp(0.0, 1.0), false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
```

### Paso 3 — Reemplazar `TacticalRadarRing` por `DualGaugePanel` en `TerminalTab.build()`

Reemplazar línea:
```dart
if (!isGov) Center(child: TacticalRadarRing(saturation: saturation, accent: accent, activeTaskId: activeTaskId)),
```

Por:
```dart
if (!isGov) Center(child: DualGaugePanel(bhi: bhi, cus: cus, accent: accent, activeTaskId: activeTaskId)),
```

### Paso 4 — Actualizar `main.dart` para pasar `_cus` y `_bhi`

En `_buildCurrentTab()`, actualizar la construcción de `TerminalTab`:
```dart
case 0: return TerminalTab(
  // ... parámetros existentes ...
  cus: _cus,   // [S25-03] NUEVO
  bhi: _bhi,   // [S25-03] NUEVO
);
```

### Paso 5 — Eliminar `TacticalRadarRing` y `RadarPainter`
La clase `TacticalRadarRing` y `RadarPainter` pueden eliminarse del archivo ya que son reemplazadas
por `DualGaugePanel` y `_ArcGaugePainter`. Verificar que no se usan en ningún otro lugar antes de eliminar.

## Criterios de Aceptación
- [ ] La pantalla principal de Vanguard muestra DOS indicadores circulares (no uno)
- [ ] El indicador izquierdo está etiquetado "BHI / BÚNKER"
- [ ] El indicador derecho está etiquetado "CUS / CONTEXTO"
- [ ] Cada indicador cambia de color: cyan/verde → naranja → rojo según el valor
- [ ] El Task ID activo se muestra centrado debajo de ambos diales
- [ ] El parámetro `saturation` en `TerminalTab` puede mantenerse para compatibilidad con `_buildTelemetryPanel()`

## Restricciones (NO HACER)
- NO usar `flutter_gauge` ni ninguna librería externa — solo `CustomPaint`
- NO eliminar `_buildTelemetryPanel()` del sidebar izquierdo — solo reemplazar el dial central
- El `TacticalRadarRing` puede eliminarse solo si NO hay referencias en otros archivos

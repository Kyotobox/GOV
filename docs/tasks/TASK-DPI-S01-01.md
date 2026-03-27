# TASK-DPI-S01-01: Configurar pubspec.yaml

**Sprint**: S01-GOV-BOOTSTRAP
**Label**: [GOV]
**CP**: 2
**Gate**: GATE-RED
**Revisor**: [GOV] PO (firma RSA en baseline)
**Modelo**: Gemini Flash

## Contexto
El proyecto `antigravity_dpi` es actualmente un skeleton Dart generado por defecto.
Esta tarea establece todas las dependencias necesarias para los módulos planificados.
**Referencia**: `Base2/kernel_manifest.json` (para entender qué reemplazamos)
**Referencia de Seguridad**: `Base2/vanguard_agent/pubspec.yaml` (dependencias RSA existentes)

## Scope
- `pubspec.yaml` (ÚNICO archivo modificable)

## Implementación

Reemplazar el `pubspec.yaml` actual con las siguientes dependencias:

```yaml
name: antigravity_dpi
description: Governance & Security Control Plane for Base2 Kernel DPI
version: 1.0.0

environment:
  sdk: ^3.11.1

dependencies:
  args: ^2.7.0
  path: ^1.9.1
  pointycastle: ^4.0.0   # RSA/SHA-256 nativo (Vanguard)
  watcher: ^1.2.1         # File watching para Watch Mode
  crypto: ^3.0.3          # SHA-256 para Signed Pulse / ChainedLog
  convert: ^3.1.1         # Base64 encoding para firmas RSA

dev_dependencies:
  lints: ^6.0.0
  test: ^1.25.6
```

## DoD (Definition of Done)
- [ ] `pubspec.yaml` actualizado con todas las dependencias listadas.
- [ ] `dart pub get` ejecuta sin errores.
- [ ] No hay dependencias de Flutter ni de UI.
- [ ] `dart analyze` retorna 0 issues.

## Comando de Verificación
```powershell
cd c:\Users\Ruben\Documents\antigravity_dpi
dart pub get
dart analyze
```

## Baseline
`gov baseline "S01-01: pubspec.yaml dependencies configured" GATE-RED`

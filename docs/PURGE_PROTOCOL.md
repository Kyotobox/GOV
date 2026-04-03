# [PROTOCOLO] Purga y Recuperación de Integridad (NUCLEUS-V9)

Este documento define el procedimiento estándar para eliminar la saturación operativa y cognitiva del búnker, restaurando el estado **NOMINAL** del sistema.

## 1. Naturaleza de la Saturación

La saturación en el ecosistema **antigravity_dpi** se manifiesta de dos formas:
- **Saturación Operativa**: Procesos huérfanos (`dart.exe`, `flutter.exe`), artefactos de construcción corruptos o bloqueos de red que impiden la compilación.
- **Saturación Cognitiva**: Acumulación de interacciones (CUS) que degrada el **SHS** por encima del 90%, induciendo alucinaciones o deriva de contexto en la IA.

## 2. Herramientas de Recuperación

### A. Recuperación de Emergencia (`scripts/purge.ps1`)
Diseñada para fallos de infraestructura general. Debe ejecutarse desde PowerShell.
```powershell
.\scripts\purge.ps1        # Limpieza básica y reseteo de métricas
.\scripts\purge.ps1 --full # Limpieza profunda incluyendo reinstalación de dependencias
```

### B. Purga de Gobernanza (`gov purge`)
Comando integrado para el mantenimiento preventivo y limpieza de bajo nivel (zombies y contadores).
```bash
gov purge
```

## 3. Pasos del Protocolo (Manual)

Si las herramientas automáticas fallan, siga este orden estricto:

1.  **Kill-Switch**: Finalizar cualquier instancia de `dart.exe` o `flutter.exe`.
2.  **Infrastructure Wipe**: Eliminar carpetas `.dart_tool` y `build`.
3.  **DNA Verification**: Asegurar que `bin/gov.exe` coincide con el hash en `vault/intel/gov_hash.sig`.
4.  **Relay Reset**: Ejecutar `gov handover` seguido de `gov takeover` para liberar la presión contextual.

## 4. Umbrales de Activación

| Métrica | Umbral | Acción Recomendada |
| :--- | :--- | :--- |
| **SHS** | > 85% | `gov purge` preventivo. |
| **SHS** | > 90% | `gov handover` obligatorio. |
| **CUS** | > 45% | `gov purge` + `takeover` para resetear sesión. |
| **Zombies** | > 5 | `gov housekeeping`. |

---
*Referencia: SHS_V5_EVOLUTION.md | VISION.md*

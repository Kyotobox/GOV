# PROTOCOLO DE ESTANDARIZACIÓN BASE2: NUCLEUS-V9 (v9.0.1)

Este documento sirve como instrucción maestra para que el proyecto **Base2** asuma la nueva versión de gobernanza y sincronice su estado con el Kernel v9.0.1.

## 1. Identidad de Versión
**Versión de Referencia**: v9.0.1 (NUCLEUS-V9 Final Hardened)  
**Hash Maestro Certificado**: `F31FA1D371C8CAE0125BED99C8EEF307AD618E9C8583ECC6F596562BB00FCC5E7`
  
**Estado de Gobernanza**: SEALED / GOLD

## 2. Instrucciones de Implementación (Prompt para Base2)

> "Asume el rol de Operador de Fábrica Base2. Se ha liberado la versión v9.0.1 del motor de gobernanza Antigravity DPI. Ejecuta los siguientes pasos para normalizar el entorno:"

### Paso A: Sincronización de ADN
1.  **Recepción de Binarios**: Copia los nuevos `gov.exe` y `vanguard.exe` de la carpeta de distribución a la raíz de tu proyecto Base2.
2.  **Verificación de Firma**: Ejecuta `gov audit` para asegurar que el motor reconoce el búnker de Base2 y la cadena de ADN es válida.

### Paso B: Takeover de Contexto
1.  **Relevo de Sesión**: Ejecuta `gov takeover` para iniciar el primer hilo de ejecución bajo el protocolo NUCLEUS-V9.
2.  **Validación de Pulso**: Verifica en el Vanguard Agent que la **VERSIÓN KERNEL** mostrada sea `9.0.1` y que el **PUNTO DE SALUD (SHS)** sea nominal.

### Paso C: Registro y Baseline
1.  **Primer Baseline**: Ejecuta `gov baseline "Sincronización v9.0.1 NUCLEUS-V9"` para anclar el estado inicial de la fábrica.
2.  **Limpieza Forense**: Ejecuta `gov housekeeping` para purgar cualquier residuo de versiones anteriores.

## 3. Criterio de Éxito
La fábrica se considera **Certificada v9.0.1** si:
- El comando `gov status` reporta Versión 9.0.1 y Sistema SEALED.
- El `CUS` (Context Utilization Score) opera bajo la fórmula determinista v4.0.
- El Evaluador de Estados v2.0 está activo y monitoreando el búnker.

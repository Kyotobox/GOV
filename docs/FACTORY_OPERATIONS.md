# Protocolo de Operaciones de Fábrica (v9.3.0 NUCLEUS-EVO)

Este documento define los procedimientos estándar para la generación de semillas, replicación de ADN y expansión de la flota soberana.

## 1. Generación de Semillas (Seed Generation)
Para crear un nuevo nodo o "integrante" de la flota:
1.  **Clonar Estructura**: Copiar la estructura base de un nodo (bin/, lib/, vault/).
2.  **Identidad**: Generar una nueva firma RSA pública/privada en `vault/po_private.xml` (si el nodo es soberano).
3.  **Registro**: Añadir la entrada del nuevo nodo en `vault/intel/fleet_registry.json` del Kernel.
4.  **Baseline Inicial**: Ejecutar la utilidad de sincronización de ADN.

## 2. Sincronización de ADN (DNA Sync)
Cuando se realizan cambios en el código fuente (`.dart`) o se actualiza el Kernel, es obligatorio re-sellar el ADN para evitar los `Mismatch` de integridad:

### Procedimiento Automatizado:
El Kernel provee la herramienta `tmp/sync_dna.dart` para alinear los manifiestos:
```bash
dart tmp/sync_dna.dart <ruta_al_proyecto>
```
Este comando:
- Recalcula los hashes de `bin/` y `lib/`.
- Regenera `vault/self.hashes` (DNA de fuentes).
- Regenera `vault/kernel.hashes` (DNA del motor).

## 3. Propagación de Actualizaciones de Kernel (Fleet Upgrade)
Para desplegar una nueva versión del motor (`gov.exe`, `vanguard.exe`):
1.  **Compilación**: Compilar el Kernel en la raíz del búnker central.
2.  **Firmado**: Generar los archivos `.sig` correspondientes usando la llave maestra.
3.  **Distribución**: Copiar el binario y su firma a la carpeta `bin/` de cada nodo con la extensión `.update`.
4.  **Adopción**: Cada nodo debe ejecutar `gov upgrade` para validar la firma y activar la versión.

## 4. Auditoría Determinista
Cada sesión debe cerrarse con una auditoría completa:
- `gov audit`: Verifica integridad local.
- `gov fleet-pulse`: Verifica sincronización de versiones en toda la flota.

> [!IMPORTANT]
> **CADENA DE CUSTODIA**: Nunca modifique archivos en `vault/` manualmente. La integridad total solo se garantiza mediante el uso de las herramientas de gobernanza certificadas.

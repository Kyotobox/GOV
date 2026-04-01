# TASK-DPI-S28-04: METRICS-SPEC (Protocolo de Cálculo)

## Contexto
El Agente Vanguard muestra métricas críticas (SHS, CUS, BHI) que rigen la gobernanza del búnker. Es imperativo tener un documento SSoT que detalle los algoritmos y pesos utilizados para asegurar la transparencia y permitir auditorías manuales consistentes.

## Objetivos
- [ ] Investigar las fórmulas actuales en `gov.dart`, `telemetry_service.dart` e `integrity_engine.dart`.
- [ ] Documentar el cálculo del **CUS (Context Utilization Score)** incluyendo penalizaciones de S27.
- [ ] Documentar el cálculo del **BHI (Bunker Health Index)** con la ponderación 70/30 (Integridad/Higiene).
- [ ] Definir los umbrales de saturación y las acciones automáticas disparadas (Hard Gates).
- [ ] Publicar el documento en `docs/gate-gold/PROTOCOLO_CALCULO.md`.

## Criterios de Aceptación
1. El documento debe ser técnicamente exacto comparado con el código fuente v8.3.x.
2. Debe incluir ejemplos de cálculo para situaciones nominales y críticas.
3. El documento debe ser accesible desde el dashboard de gobernanza.

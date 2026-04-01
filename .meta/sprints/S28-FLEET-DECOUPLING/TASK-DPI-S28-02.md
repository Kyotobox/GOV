# TASK-DPI-S28-02: SERVICE-REFACTOR

## Descripción
Migrar la lógica de agregación de pulsos de flota (`runFleetPulse`) desde `gov.dart` hacia un nuevo módulo de servicios especializado.

## Criterios de Aceptación
- Desacoplamiento de la lógica de kernel.
- Inyección de dependencias para el agregador.
- Test unitarios de pulsos simulando oráculos.

# Servicio de Telemetría (TelemetryService)

**Ruta**: `lib/src/telemetry/telemetry_service.dart`
**Nivel de Gobernanza**: GATE-GOLD

## 1. Resumen

El `TelemetryService` es un componente `GATE-GOLD` cuya función es medir y cuantificar de forma objetiva la salud del sistema y la carga cognitiva del equipo de desarrollo. Genera dos métricas clave: el **System Health Score (SHS)** y el **Cognitive Pulse (CP)**. Estas métricas no son para evaluar el rendimiento, sino para actuar como un mecanismo de seguridad que previene el agotamiento (`burnout`) y la degradación de la calidad del código debido a la fatiga, siendo un pilar del protocolo de relevos (`Handover`).

## 2. Responsabilidades Clave

- **Análisis del Historial Git**: Procesa el historial de `commits` desde el último `baseline` para extraer datos brutos (líneas añadidas, eliminadas, archivos modificados).
- **Cálculo de SHS**: Calcula un puntaje de salud del sistema basado en la volatilidad y la frecuencia de los cambios en el código.
- **Cálculo de Pulso Cognitivo (CP)**: Estima la carga cognitiva y la fatiga del equipo basándose en la intensidad y duración de las sesiones de trabajo.
- **Integración de Fatiga Heredada**: Incorpora el valor de `inherited_fatigue` del `session.lock` para asegurar la continuidad de la métrica entre relevos.
- **Generación de Reportes**: Provee los valores calculados para ser mostrados al usuario y almacenados en los registros de sesión.

## 3. Métricas Detalladas

### 3.1. System Health Score (SHS)
El SHS es un indicador de la estabilidad del código base. Un SHS alto (cercano al 100%) indica un desarrollo estable y enfocado, mientras que un valor bajo puede sugerir refactorizaciones masivas, reversiones frecuentes o "churn" de código, lo que justifica una revisión.

### 3.2. Cognitive Pulse (CP)
El CP mide la "energía" invertida en el sprint. Se calcula a partir de la cantidad de cambios y la dispersión de estos a través de los archivos. Un CP muy alto y sostenido es una señal de alerta temprana de posible fatiga cognitiva en el equipo.

## 4. Flujo de Cálculo

1.  **Carga de Estado Inicial**: El servicio lee el `session.lock` para obtener el valor de `inherited_fatigue`, que representa la fatiga acumulada de sesiones anteriores.
2.  **Análisis de Git**: Ejecuta un análisis sobre el repositorio Git para obtener un listado de `commits` y sus estadísticas (`--shortstat`) desde el último `baseline` o `takeover`.
3.  **Procesamiento de Métricas**: Utiliza los datos de Git y el valor de fatiga heredada para aplicar las fórmulas matemáticas correspondientes y obtener los valores actuales de SHS y CP.
4.  **Actualización de Estado**: Los valores calculados se utilizan para actualizar el estado de la sesión actual, y el valor de fatiga final se prepara para ser persistido en el siguiente `handover`, convirtiéndose en la `inherited_fatigue` de la próxima sesión.

## 5. Integración y Protocolos

- **Comando `gov status`**: Es el principal consumidor de este servicio, mostrando en tiempo real el SHS y CP al desarrollador.
- **Protocolo `handover`**: Al finalizar una sesión, el valor final de fatiga se escribe en el archivo de relevo, asegurando que el siguiente analista tenga un punto de partida preciso sobre el estado cognitivo del proyecto, como lo exige el manifiesto `GEMINI.md`.

## 6. Artefactos Relacionados

-   `session.lock`: Almacena el valor de `inherited_fatigue` que sirve como entrada para el cálculo.
-   `.git/`: El historial de `commits` es la fuente primaria de datos para el análisis.
-   `HISTORY.md`: Aunque no es una entrada directa, los `baselines` registrados aquí definen los puntos de partida para el análisis de Git.
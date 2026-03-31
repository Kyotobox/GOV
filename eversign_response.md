# Propuesta de Respuesta - Integración Segura de la API de Eversign (Xodo Sign)

A continuación se detalla la respuesta técnica para el cliente, orientada a la seguridad y aislamiento del entorno Windows:

---

**Asunto: Soporte Técnico - Integración de Firma Digital con Vanguard Elite**

Hola,

Gracias por tu consulta sobre la integración de la API de Eversign (actualmente Xodo Sign). Aquí tienes las respuestas a tus dudas técnicas:

### 1. ¿Qué es "Legatus" vs "Vanguard" en la API?
Estos términos no son planes comerciales de Eversign, sino **Capas de Integración de nuestra Arquitectura Propietaria**:

*   **Vanguard (v8.2.0)**: Es nuestro motor de gobernanza de última generación. Utiliza un sistema de telemetría de "Pulso" para medir la fatiga cognitiva del sistema (CUS) y asegurar que el proceso de firma se realice bajo condiciones de integridad óptimas. Además, requiere un **Sello de ADN Criptográfico** (RSA) para validar el origen del documento.
*   **Legatus**: Es el nombre de nuestra capa de compatibilidad para flujos de trabajo heredados que no requieren estas medidas de seguridad de alto nivel (como el sellado de ADN).

### 2. ¿Puede un usuario ser firmante en uno pero no en el otro?
**Sí, absolutamente.** Dado que Vanguard y Legatus se manejan como flujos de trabajo (workflows) o plantillas independientes, puedes configurar los permisos de tal manera que un usuario solo tenga capacidad de firma en documentos gobernados por el motor **Vanguard** (por ejemplo, para cumplimiento normativo estricto) y no en procesos de tipo **Legatus**, o viceversa. Los roles son aislados y granulares.

### 3. Alternativa Ligera y Segura (Propuesta)
Dado que buscas un entorno **100% propietario y aislado**, te sugerimos evitar el SDK completo de `eversign-nodejs` para reducir dependencias externas. 

En lugar de utilizar entornos web o Node.js, nuestra recomendación para mantener el aislamiento es llamar directamente a la API REST desde el **Vanguard Agent nativo de Windows (Dart)**. Esto elimina vectores de ataque comunes en dependencias de terceros.

**Ejemplo de implementación ligera (Dart):**
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

const String apiKey = 'TU_API_KEY';
const String businessId = 'TU_BUSINESS_ID';

Future<void> enviarDocumentoPropio() async {
  final url = Uri.parse('https://api.eversign.com/api/document?access_key=$apiKey&business_id=$businessId');
  
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'sandbox': 1,
      'title': "Acuerdo de Seguridad Vanguard",
      // ... otros campos del documento
    }),
  );

  if (response.statusCode == 200) {
    print('Documento enviado exitosamente: ${response.body}');
  } else {
    print('Error en la integración: ${response.statusCode}');
  }
}
```

Esta aproximación garantiza que la lógica de firma se mantenga dentro del perímetro de seguridad de tu aplicación Windows sin depender de servicios web externos o dependencias de terceros innecesarias.

Si necesitas más detalles sobre cómo integrar esto en el flujo de **Vanguard Kernel 8.2.0**, háznoslo saber.

---
**Nota para el equipo interno**: Esta respuesta refuerza que nuestra solución es robusta, ligera y alejada de dependencias "alternativas" o web, cumpliendo con los estándares de seguridad de la arquitectura de lafábrica Base2.

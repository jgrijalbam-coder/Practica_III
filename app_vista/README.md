# VISTA — Semana 14: servicios y API

Arquitectura de Sistemas I — Universidad Central.

Esta entrega implementa servicios y endpoints para **RF-10 (configurar preferencias)** y la parte de persistencia y consulta de **RF-14 (destinos frecuentes)**. La arquitectura es:

```text
API Shelf → servicio de aplicación → repositorio → SQLite
```

Los handlers traducen HTTP y delegan las reglas a los servicios. Los repositorios encapsulan las consultas SQL. Los servicios reciben repositorios por constructor, por lo que se pueden probar con dobles sin abrir SQLite.

**Alcance de RF-14:** el backend permite guardar, buscar y listar destinos. El criterio de proyecto de decir “Casa” e iniciar la ruta requiere integrar voz y navegación; esa parte no queda demostrada por estos endpoints ni por las pruebas actuales.

## 1. Requisitos funcionales y responsabilidades

### RF-10 — Configurar preferencias

| Elemento | Implementación |
|---|---|
| Servicio | `ConfiguracionService` |
| Operaciones | `obtener(idUsuario)` y `guardar(idUsuario, DatosConfiguracion)` |
| Reglas del proyecto | Sensibilidad 0.4, 0.5 o 0.7; velocidad de voz entre 0.8 y 2.0; modo de tonos permitido; volumen maestro entre 50 y 95. Valores iniciales: 0.5, 1.2, `frecuencia_simple` y 60. |
| Repositorios | `RepositorioUsuarios.buscarPorId`; `RepositorioConfiguracion.obtener` y `guardar`. |
| Resultado | Lectura de la configuración o escritura confirmada y datos guardados devueltos. |
| Rechazos probados | ID inválido, usuario ausente, configuración ausente y valores fuera de rango; no se debe escribir ante una validación rechazada. |

La plantilla de alcance vincula RF-10 con CU-07 y HU-11. Las reglas RN-06 y RN-14 son reglas de negocio, no RNF de calidad. Los rangos anteriores se aplican en el dominio y también están restringidos por el esquema SQLite. La confirmación de la persona antes de guardar pertenece a la interacción de la interfaz y queda por comprobar al integrar esa pantalla.

### RF-14 — Destinos frecuentes

| Elemento | Implementación |
|---|---|
| Servicio | `DestinosService` |
| Operaciones | `guardar(idUsuario, etiqueta, latitud, longitud)`, `buscarPorId(idDestino)` y `listarPorUsuario(idUsuario)`. |
| Reglas | IDs positivos; usuario existente al guardar/listar; etiqueta no vacía y única por usuario sin distinguir mayúsculas; latitud de -90 a 90 y longitud de -180 a 180. |
| Repositorios | `RepositorioUsuarios.buscarPorId`; `RepositorioDestinos.guardar`, `buscarPorId` y `listarPorUsuario`. |
| Resultado | Guardar devuelve el ID real persistido; buscar devuelve el destino o comunica ausencia; listar permite una lista vacía. |
| Rechazos probados | Etiqueta repetida, coordenadas/etiqueta inválidas, usuario inexistente e ID o destino ausente. |

La columna `direccion` es obligatoria en SQLite aunque el endpoint no la exige. Si no se envía, el servicio deriva un texto a partir de las coordenadas para cumplir el esquema. El flujo de voz que inicia una ruta con un destino guardado todavía requiere integración con los módulos de voz y navegación.

### Persistencia y recursos

Los servicios no abren conexiones ni administran transacciones. Cada escritura es una sentencia SQLite; `BaseDatos` administra la conexión y quien la abre debe cerrarla con `BaseDatos.cerrar()`. El proceso del servidor cierra la conexión al finalizar. No se ha probado aquí una operación de negocio con varias escrituras que requiera confirmación o reversión conjunta.

## 2. Contratos HTTP implementados

Base local: `http://localhost:8080`. Las respuestas son JSON; los errores esperados usan `{"detail":"..."}`. Los fallos internos se registran y se devuelven como HTTP 500 genérico.

| RF | Método y ruta | Entrada | Éxito | Errores esperados | Servicio |
|---|---|---|---|---|---|
| RF-10 | GET `/api/usuarios/{id}/configuracion` | ID positivo en la ruta | 200 con configuración | 400 ID inválido; 404 usuario/configuración ausente; 500 interno | `ConfiguracionService.obtener` |
| RF-10 | PUT `/api/usuarios/{id}/configuracion` | JSON con campos de configuración | 200 con configuración guardada | 400 JSON/campo/rango inválido; 404 usuario ausente; 500 interno | `ConfiguracionService.guardar` |
| RF-14 | POST `/api/usuarios/{id}/destinos` | JSON `etiqueta`, `latitud`, `longitud`; `direccion` opcional | 201 con destino e ID real | 400 formato/rango; 404 usuario ausente; 409 etiqueta duplicada; 500 interno | `DestinosService.guardar` |
| RF-14 | GET `/api/destinos/{id}` | ID positivo en la ruta | 200 con destino | 400 ID inválido; 404 destino ausente; 500 interno | `DestinosService.buscarPorId` |
| RF-14 | GET `/api/usuarios/{id}/destinos` | ID positivo en la ruta | 200 con lista, incluso vacía | 400 ID inválido; 404 usuario ausente; 500 interno | `DestinosService.listarPorUsuario` |

Ejemplo de configuración:

```json
{
  "sensibilidad": 0.7,
  "velocidad_voz": 1.5,
  "modo_tonos": "espacializada",
  "volumen_maestro": 80
}
```

Ejemplo de destino:

```json
{
  "id_destino": 3,
  "id_usuario": 1,
  "etiqueta": "Parque",
  "latitud": 4.62,
  "longitud": -74.08
}
```

## 3. RNF y trazabilidad de calidad

Se conservan los identificadores del documento del proyecto. **RFN-06, RFN-07 y RFN-08 no se presentan como requisitos originales:** son pruebas/criterios complementarios incorporados durante esta entrega. RFN-05 aparece en el documento como duplicado de RFN-01, con reemplazo aún por definir.

| RF/RNF | Característica de calidad | Escenario y meta | Resultado/evidencia compartida |
|---|---|---|---|
| RF-01 / RFN-01 | Eficiencia de desempeño / comportamiento temporal | Inferencia YOLO <100 ms, pipeline local ≤200 ms y captura a sonido <300 ms, según el documento del proyecto. | **Pendiente:** las pruebas compartidas no miden el flujo completo de cámara a audio en el teléfono. |
| Proyecto / RFN-02 | Eficiencia energética / autonomía | Navegación continua durante 4 horas con modelo activo, Bluetooth y brillo mínimo, según el documento. | **Pendiente:** requiere prueba prolongada en dispositivo. |
| RF-10, RF-14 / RFN-03 | Capacidad de interacción / inclusividad | Verificar lector de pantalla, contraste y acceso a controles en la interfaz. | **Pendiente:** no se compartió una prueba manual de accesibilidad. |
| RF-10, RF-14 / RFN-04 | Seguridad / privacidad | El documento pide proteger datos y evitar transferencia continua de video. | **Parcial:** revisión de código/semilla local; no demuestra una auditoría completa ni una transmisión TLS a nube. |
| Proyecto / RFN-05 | Duplicado de RFN-01 en el documento fuente | El propio documento recomienda eliminarlo o reemplazarlo por disponibilidad sin conexión, aún por definir. | **Pendiente de decisión del equipo/docente:** no se inventa una meta ni se renumera. |
| RF-10, RF-14 / prueba complementaria | Mantenibilidad / capacidad para ser probado | Ejecutar servicios con repositorios simulados: válidos y rechazos/ausencias, sin conexión real. | **Cumple según la salida compartida:** `test/servicios_test.dart`, 15 pruebas pasaron. No se asigna un nuevo ID RFN. |
| RF-14 / prueba complementaria | Persistencia y recuperación | Guardar diez destinos y recuperarlos desde una conexión nueva. | **Cumple según la salida compartida:** 10/10 recuperados en `test/persistencia_test.dart`. |
| RF-10 / prueba complementaria | Tiempo de respuesta HTTP | 20 GET consecutivos, cada respuesta ≤50 ms. Este umbral añadido no sustituye RFN-01. | **No cumple en la última ejecución compartida:** 19/20. La primera lectura fue 94.615 ms; las otras 19 estuvieron entre 11.235 y 17.805 ms. Evidencia: `test/rnf_desempeno_test.dart`. |

La meta HTTP de 50 ms es más estricta y mide otra cosa que RFN-01. No se rebaja el umbral para declarar éxito. La prueba enfocada falla si alguna respuesta supera el umbral individual.

## 4. Ejecutar el proyecto y las pruebas

Requisitos usados en las salidas compartidas: Flutter 3.47.8 y Dart 3.13.7. Ejecuta desde la carpeta `app_vista`:

```powershell
flutter pub get
flutter analyze
flutter test test/servicios_test.dart --reporter expanded
flutter test test/persistencia_test.dart --reporter expanded
flutter test test/api_test.dart --reporter expanded
flutter test test/widget_test.dart --reporter expanded
flutter test test/rnf_desempeno_test.dart --reporter expanded
```

Resultados comunicados por el equipo: análisis estático sin problemas; servicios 15/15; persistencia 13/13; API 6/6; widget 1/1. La prueba de desempeño HTTP quedó en 19/20 y falló por la primera lectura de 94.615 ms. Son ejecuciones independientes compartidas en la conversación; no equivalen a una nueva ejecución realizada al editar este README.

### Servidor HTTP

```powershell
$env:PORT = "8080"
$env:DB_PATH = "vista_pruebas.db"
dart run bin/server.dart
```

El puerto predeterminado es 8080. `DB_PATH` elige el archivo SQLite (predeterminado: `vista.db` en el directorio actual). Si el archivo no existe, el servidor crea el esquema y carga la semilla. Para reiniciar, detén el servidor y elimina **solo el archivo de pruebas** antes de volver a iniciarlo.

### Ejemplos de cliente HTTP

Obtener configuración:

```powershell
curl.exe http://localhost:8080/api/usuarios/1/configuracion
```

Guardar configuración:

```powershell
curl.exe -X PUT http://localhost:8080/api/usuarios/1/configuracion -H "Content-Type: application/json" -d "{\"sensibilidad\":0.7,\"velocidad_voz\":1.5,\"modo_tonos\":\"espacializada\",\"volumen_maestro\":80}"
```

Crear un destino frecuente (la respuesta contiene el ID generado):

```powershell
curl.exe -X POST http://localhost:8080/api/usuarios/1/destinos -H "Content-Type: application/json" -d "{\"etiqueta\":\"Parque\",\"latitud\":4.62,\"longitud\":-74.08}"
```

Buscar un destino y listar los del usuario:

```powershell
curl.exe http://localhost:8080/api/destinos/1
curl.exe http://localhost:8080/api/usuarios/1/destinos
```

Las pruebas crean bases temporales con `db/schema.sql` y `db/seed.sql`. En la semilla, el usuario 1 tiene configuración y destinos de ejemplo; el usuario 2 no tiene configuración ni destinos.

## 5. Relevo a la interfaz y pendientes

- RF-10 expone GET y PUT de configuración por usuario.
- RF-14 expone POST para guardar destinos, GET por ID y GET para listar por usuario.
- Los errores esperados son 400 (entrada inválida), 404 (usuario/recurso ausente), 409 (etiqueta duplicada) y 500 genérico (fallo interno).
- CORS permite orígenes localhost y 127.0.0.1 con sus puertos; habilita GET, POST, PUT y OPTIONS.
- Al integrar la interfaz falta comprobar llamadas reales a la API, confirmación antes de guardar preferencias, accesibilidad, selección por voz e inicio de ruta.
- Siguen pendientes las mediciones originales de RFN-01, RFN-02, RFN-03 y la decisión sobre RFN-05. La prueba complementaria HTTP de 50 ms tampoco cumple en la última ejecución compartida.

## 6. Checklist de entrega

| Criterio | Estado según el código y las evidencias compartidas |
|---|---|
| Dos RF con identificadores oficiales | **Parcial:** servicios y API para RF-10 y operaciones de persistencia de RF-14; falta integrar el criterio completo de inicio de ruta por voz. |
| Responsabilidades API → servicio → repositorio → BD | **Implementado y documentado** en las clases y contratos descritos arriba. |
| Pruebas funcionales de ambos RF | **Ejecutadas:** servicios, API y persistencia pasaron en las ejecuciones independientes comunicadas. |
| RNF originales con resultado y evidencia | **Parcial:** RFN-01/02/03 requieren pruebas en dispositivo/interfaz; RFN-04 solo tiene revisión parcial; RFN-05 necesita decisión. |
| Pruebas complementarias de aislamiento y persistencia | **Pasaron según las salidas compartidas:** dobles de repositorio y recuperación de 10 destinos. |
| Tiempo HTTP complementario ≤50 ms | **No cumple:** 19/20 en la última ejecución compartida. |
| Ejecución, URL, puertos, reinicio y contratos | **Documentados** en las secciones 2 y 4. |
| `flutter analyze` | **Sin problemas** en la salida compartida por el equipo. |

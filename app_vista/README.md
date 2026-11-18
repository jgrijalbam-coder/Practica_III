# VISTA - Semana 14: servicios y API

Arquitectura de Sistemas I - Universidad Central. Esta entrega implementa la lógica de negocio y la API de **RF-10** (configurar preferencias) y **RF-DF** (destinos frecuentes, identificador provisional por confirmar). La prioridad se conserva: RF-10 prioridad 1 y RF-DF prioridad 2.

La arquitectura es **API Shelf → servicios → repositorios → SQLite**. Los handlers traducen HTTP y delegan las reglas a los servicios; el SQL permanece en los repositorios. No se incluyen pantallas, voz, cálculo de rutas, nube ni permisos de acompañante.

## 1. Servicios y reglas

### RF-10: configurar preferencias

| Elemento | Contrato |
|---|---|
| Servicio | `ConfiguracionService` |
| Entrada | `obtener(idUsuario)`; `guardar(idUsuario, DatosConfiguracion)`. |
| Reglas | El id debe ser entero positivo y el usuario debe existir. Sensibilidad: 0.4, 0.5 o 0.7. Velocidad de voz: 0.8–2.0. Modo: `frecuencia_simple` o `espacializada`. Volumen maestro: 50–95. En la API, los campos omitidos al guardar toman los valores por defecto: 0.5, 1.2, `frecuencia_simple` y 60. |
| Repositorios | `RepositorioUsuarios.buscarPorId`; `RepositorioConfiguracion.obtener` y `RepositorioConfiguracion.guardar`. |
| Resultado válido | `obtener` devuelve las preferencias existentes. `guardar` inserta o actualiza y devuelve los datos leídos después de escribir. |
| Rechazo esperado | Entrada inválida: `ValidacionError` (ERR-15). Usuario inexistente: `UsuarioNoEncontrado` (ERR-16). Usuario sin preferencias: `ConfiguracionNoEncontrada` (ERR-16). |
| RN-06 y RN-14 | No se encontró su texto en el README o los archivos disponibles. Queda un TODO en `lib/dominio/reglas_configuracion.dart`; no se inventan reglas. |

### RF-DF: destinos frecuentes

| Elemento | Contrato |
|---|---|
| Servicio | `DestinosService` |
| Entrada | `guardar(idUsuario, etiqueta, latitud, longitud)`; `buscarPorId(idDestino)`; `listarPorUsuario(idUsuario)`. |
| Reglas | Id positivo; usuario existente al guardar y listar; etiqueta no vacía después de recortar; latitud entre -90 y 90; longitud entre -180 y 180. La etiqueta es única por usuario sin distinguir mayúsculas. |
| Repositorios | `RepositorioUsuarios.buscarPorId`; `RepositorioDestinos.guardar`, `buscarPorId` y `listarPorUsuario`. |
| Resultado válido | Guardar devuelve el destino con id real; buscar devuelve el destino; listar puede devolver una lista vacía. |
| Rechazo esperado | Entrada inválida: `ValidacionError` (ERR-15). Usuario inexistente: `UsuarioNoEncontrado` (ERR-16). Destino ausente: `DestinoNoEncontrado` (ERR-16). Etiqueta repetida: `EtiquetaDuplicada` (ERR-16; HTTP 409). |
| Dirección | El esquema tiene una columna `direccion NOT NULL`, aunque el contrato solicitado para el endpoint no la exige. Si el JSON no la incluye, el servicio guarda un texto derivado de las coordenadas. No se devuelve en el JSON. |

Los servicios dependen de interfaces de repositorio inyectadas por constructor y no conocen HTTP. Cada operación SQL es una sentencia atómica que SQLite confirma o revierte. `BaseDatos` posee la conexión: quien la abre es responsable de llamar `BaseDatos.cerrar()`. En el servidor, el proceso cierra la conexión cuando termina.

## 2. Contratos de API

Base local: `http://localhost:8080`. Las respuestas son JSON; los errores tienen la forma `{"detail":"..."}`. Los fallos internos se registran en el servidor, responden HTTP 500 con un mensaje genérico y no exponen detalles técnicos.

| RF | Método y ruta | Entrada | Éxito | Errores | Servicio |
|---|---|---|---|---|---|
| RF-10 | GET `/api/usuarios/{id}/configuracion` | Id positivo en ruta | 200, configuración | 400 id inválido; 404 usuario o configuración ausente; 500 interno | `ConfiguracionService.obtener` |
| RF-10 | PUT `/api/usuarios/{id}/configuracion` | JSON con campos de configuración; se pueden omitir campos para usar valores por defecto | 200, configuración guardada | 400 JSON/campo/rango inválido; 404 usuario ausente; 500 interno | `ConfiguracionService.guardar` |
| RF-DF | POST `/api/usuarios/{id}/destinos` | JSON con `etiqueta`, `latitud`, `longitud`; `direccion` opcional por la restricción del esquema | 201, destino con id real | 400 formato/rango; 404 usuario ausente; 409 etiqueta duplicada; 500 interno | `DestinosService.guardar` |
| RF-DF | GET `/api/destinos/{id}` | Id positivo en ruta | 200, destino | 400 id inválido; 404 destino ausente; 500 interno | `DestinosService.buscarPorId` |
| RF-DF | GET `/api/usuarios/{id}/destinos` | Id positivo en ruta | 200, lista (puede estar vacía) | 400 id inválido; 404 usuario ausente; 500 interno | `DestinosService.listarPorUsuario` |

Configuración de ejemplo:

```json
{
  "sensibilidad": 0.7,
  "velocidad_voz": 1.5,
  "modo_tonos": "espacializada",
  "volumen_maestro": 80,
  "fecha_actualizacion": "2026-11-17T10:00:00.000"
}
```

Destino de ejemplo:

```json
{
  "id_destino": 3,
  "id_usuario": 1,
  "etiqueta": "Parque",
  "latitud": 4.62,
  "longitud": -74.08
}
```

## 3. Matriz RF-RNF

Los identificadores RFN-02 y RFN-05 se conservan, pero sus enunciados no aparecen en el README previo ni en los archivos revisados; quedan pendientes de recuperar del documento fuente. RFN-06, RFN-07 y RFN-08 corresponden a criterios añadidos para esta entrega. Las etiquetas ISO se mantienen cuando están documentadas; no se infieren para los criterios pendientes.

| RF/RNF | Calidad ISO | Prueba y meta | Resultado y evidencia |
|---|---|---|---|
| RFN-01 — RF-10 | Eficiencia de desempeño / comportamiento temporal | Aplicar sensibilidad sin reiniciar pipeline; alerta <300 ms y pipeline local ≤200 ms | **Pendiente semana 3**: requiere medición en el teléfono. |
| RFN-02 | Pendiente de especificación original | Meta y prueba no disponibles en los archivos revisados | **Pendiente**: recuperar identificador y criterio originales; no se inventan. |
| RFN-03 — RF-10, RF-DF | Capacidad de interacción / inclusividad (NTC 5854) | Controles accesibles con lector de pantalla y alto contraste; prueba manual con TalkBack | **Pendiente semana 3**: no hay prueba manual ni captura en esta entrega. |
| RFN-04 — RF-10, RF-DF | Seguridad / confidencialidad (Ley 1581 de 2012) | Esquema y datos de prueba sin credenciales reales; contraseñas como hash y direcciones locales | **Revisión de archivos**: `db/seed.sql` usa credenciales ficticias y `contrasena_hash`; no se guardan credenciales reales. |
| RFN-05 | Pendiente de especificación original | Meta y prueba no disponibles en los archivos revisados | **Pendiente**: recuperar identificador y criterio originales; no se inventan. |
| RFN-06 — RF-10, RF-DF | Mantenibilidad / capacidad para ser probado | Servicios con dobles, sin SQLite: resultado válido y rechazo/ausencia por servicio | **Verificado** en la suite completa: 15 pruebas de servicios pasaron con dobles, sin abrir SQLite. Evidencia: `test/servicios_test.dart`. |
| RFN-07 — RF-DF | Fiabilidad / recuperabilidad | Guardar 10 destinos, abrir conexión nueva; recuperar 10/10 | **Verificado**: 10 de 10 destinos se recuperaron tras abrir una conexión nueva. Evidencia: caso RFN-07 de `test/persistencia_test.dart`. |
| RFN-08 — RF-10 | Eficiencia de desempeño / comportamiento temporal | 20 GET consecutivos desde cliente HTTP; cada respuesta completa ≤50 ms, sin usar promedio | **No cumple en las dos mediciones API**: 19/20 cumplieron en cada ejecución. La prueba enfocada registró 210.255 ms en la primera respuesta; la suite completa registró 242.875 ms. En esta última, las otras 19 quedaron entre 15.642 y 42.252 ms. Evidencia: salida de `test/rnf_desempeno_test.dart`. Se conserva el umbral. |

RFN-01 y RFN-03 no están verificados: permanecen pendientes para la semana 3.

## 4. Ejecución

### Requisitos

Flutter 3.47.8 y Dart 3.13.7; SQLite en modo FFI para el servidor y las pruebas. No se necesita emulador ni credenciales. Ejecuta los comandos desde `app_vista`.

```sh
flutter pub get
flutter analyze
flutter test
```

La suite incluye persistencia, servicios con dobles, API HTTP y RFN-08. En la ejecución final, 35 pruebas pasaron y falló RFN-08 porque la primera respuesta tardó 242.875 ms. El test falla si cualquier respuesta supera 50 ms; no se usa el promedio para decidir.

### Servidor

```sh
dart run bin/server.dart
```

- Puerto: variable `PORT`; por defecto `8080`.
- Archivo SQLite: variable `DB_PATH`; por defecto `vista.db` en la carpeta actual.
- URL local: `http://localhost:8080`.

En PowerShell, por ejemplo:

```powershell
$env:PORT = "8080"
$env:DB_PATH = "vista.db"
dart run bin/server.dart
```

Si el archivo de `DB_PATH` no existe, el servidor crea esquema y semilla inicial. Para reiniciar los datos de prueba, detén el servidor, elimina ese archivo de base de datos y vuelve a iniciarlo. Hazlo solo con la base de pruebas.

### Restablecer y comprobar la base de pruebas

Las pruebas crean su propio archivo temporal a partir de `db/schema.sql` y `db/seed.sql`, y lo eliminan al terminar. El usuario 1 inicia con configuración (0.5, 1.2, `frecuencia_simple`, volumen 60) y destinos “Casa” y “Universidad”; el usuario 2 inicia sin configuración ni destinos.

### Ejemplos curl

Obtener configuración:

```sh
curl.exe http://localhost:8080/api/usuarios/1/configuracion
```

Guardar configuración:

```sh
curl.exe -X PUT http://localhost:8080/api/usuarios/1/configuracion -H "Content-Type: application/json" -d "{\"sensibilidad\":0.7,\"velocidad_voz\":1.5,\"modo_tonos\":\"espacializada\",\"volumen_maestro\":80}"
```

Crear destino frecuente (respuesta 201 con `id_destino` real):

```sh
curl.exe -X POST http://localhost:8080/api/usuarios/1/destinos -H "Content-Type: application/json" -d "{\"etiqueta\":\"Parque\",\"latitud\":4.62,\"longitud\":-74.08}"
```

Buscar destino por id:

```sh
curl.exe http://localhost:8080/api/destinos/1
```

Listar destinos de un usuario:

```sh
curl.exe http://localhost:8080/api/usuarios/1/destinos
```

## 5. Relevo a interfaz

- Configuración: GET y PUT por id de usuario. Los campos del JSON son `sensibilidad`, `velocidad_voz`, `modo_tonos`, `volumen_maestro` y `fecha_actualizacion`.
- Destinos: POST para guardar; GET por id; GET de la lista por usuario. El JSON de destino entrega `id_destino`, `id_usuario`, `etiqueta`, `latitud` y `longitud`.
- Códigos: 400 entrada inválida, 404 recurso/usuario ausente, 409 etiqueta duplicada, 500 fallo interno genérico.
- Origen CORS: permite `http://localhost` y sus puertos, además de `http://127.0.0.1` y sus puertos. Métodos habilitados: GET, POST, PUT y OPTIONS.
- Pendientes de calidad: RFN-01 (latencia del pipeline), RFN-03 (accesibilidad manual), RN-06/RN-14 (reglas por precisar), RFN-02/RFN-05 (definiciones fuente) y RFN-08 (primera respuesta API por encima del umbral en la medición registrada).

## 6. Checklist de entrega

| Criterio | Estado y evidencia |
|---|---|
| Prioridad y alcance RF-10 / RF-DF conservados | **Cumple**: esta documentación y servicios mantienen prioridad 1 y 2; UI, voz, rutas, nube y permisos quedan fuera. |
| Servicios, reglas y errores documentados | **Cumple**: sección 1 y `lib/servicios/`; RN-06/RN-14 se identifican como TODO por falta de texto fuente. |
| API documentada con ejemplos coincidentes | **Cumple**: sección 2; JSON snake_case, rutas y códigos reflejan handlers y serializadores. |
| Matriz RFN-01..08 sin renumerar | **Cumple con pendientes explícitos**: sección 3; RFN-02 y RFN-05 esperan su definición original. |
| Ejecución y reinicio de datos explicados | **Cumple**: sección 4, comandos, variables, semilla y ejemplos curl. |
| Relevo a interfaz y CORS documentados | **Cumple**: sección 5. |
| Pruebas de persistencia, servicios y API | **Cumple**: en la suite completa pasaron persistencia (13), servicios (15), API (6) y widget (1). Total: 35 pruebas pasaron; RFN-08 fue la única prueba fallida. |
| RFN-08 API ≤50 ms en las 20 lecturas | **No cumple** en ambas mediciones: 19/20. En la suite completa la primera respuesta fue 242.875 ms; meta conservada. |
| `flutter analyze` sin avisos/errores | **Cumple**: `No issues found!` en la ejecución final. |
| RFN-01 y RFN-03 verificados | **Pendiente semana 3**: medición en dispositivo y prueba manual de accesibilidad. |
| Sin credenciales reales y con esquema sin cambios | **Revisión**: datos ficticios en semilla; `db/schema.sql` no se modificó para esta etapa. |

## 7. Alcance pendiente

La sensibilidad en caliente y su latencia (RFN-01), accesibilidad con lector de pantalla (RFN-03), definiciones de RFN-02/RFN-05 y textos de RN-06/RN-14 requieren información o trabajo fuera de esta etapa. RF-DF sigue siendo un identificador provisional por confirmar.

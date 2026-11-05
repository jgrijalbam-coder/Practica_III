# VISTA - Semana 13: base de datos y persistencia del corte vertical

Arquitectura de Sistemas I - Universidad Central. Equipo: Jessica Mariana Pastor Galindo, Luisa Fernanda Zambrano, Maria Jose Perez Rengifo y Jeffrey Adrian Grijalva Muñoz.

## 1. Alcance de la semana
Dos RF, en este orden: **RF-10** (configurar preferencias) y **RF-DF** (destinos frecuentes, HU-8; numero de RF provisional, por confirmar). Esta semana solo se implementa la base y el acceso a datos. **Queda fuera:** reglas de negocio, API, pantallas, voz, calculo de rutas, sincronizacion con la nube y permisos del acompanante (semanas 2 y 3).

## 2. Fichas RF-RNF

### RF-10
| Elemento | Respuesta del equipo |
|---|---|
| Identificador y enunciado | RF-10. El sistema debe permitir configurar sensibilidad de deteccion (0.4 / 0.5 por defecto / 0.7), velocidad de voz (0.8x a 2.0x, por defecto 1.2x), modo de tonos (frecuencia simple o espacializada) y volumen maestro (50 a 95). |
| Actor y resultado esperado | Persona con discapacidad visual. Sus preferencias quedan guardadas y se recuperan en la siguiente apertura de la app. |
| Prioridad y justificacion | **Prioridad 1.** Valor medio (adapta el sistema a cada persona). Alta relevancia arquitectonica: la sensibilidad se aplica en caliente al pipeline (RFN-01) y estrena la capa de datos con el patron Repository. Dependencia: crea `usuario` y `configuracion`, que RF-DF reutiliza. |
| RNF asociados | RFN-01, RFN-03, RFN-04, RFN-06, RFN-07, RFN-08 |
| ISO/IEC 25010:2023 | Ver matriz (seccion 3) |
| Condicion, medida y umbral | Ver matriz (seccion 3) |
| Prueba, evidencia y semana | Ver matriz (seccion 3) |
| Datos y operaciones | Tablas `usuario` y `configuracion`. Operaciones: `obtener(idUsuario)` y `guardar(configuracion)` (inserta o actualiza). |
| Resultado semana 1 y pendientes | Probado: lectura, escritura, persistencia en conexion nueva, usuario inexistente y valores fuera de rango. Pendiente: servicio con RN-06/RN-14 y confirmacion del usuario (semana 2), pantalla accesible (semana 3). |

### RF-DF (provisional)
| Elemento | Respuesta del equipo |
|---|---|
| Identificador y enunciado | RF-DF (por confirmar el numero). El sistema debe permitir guardar y consultar destinos frecuentes con una etiqueta (por ejemplo "Casa", "Trabajo") para iniciar la navegacion hacia ellos (HU-8). |
| Actor y resultado esperado | Persona con discapacidad visual. El destino queda guardado con un identificador real y se recupera por id o en la lista del usuario. |
| Prioridad y justificacion | **Prioridad 2.** Valor medio. Menor riesgo arquitectonico que RF-10. Depende de la tabla `usuario` que RF-10 crea, y es pequeno y viable para tres semanas. |
| RNF asociados | RFN-03, RFN-04, RFN-06, RFN-07, RFN-08 |
| ISO/IEC 25010:2023 | Ver matriz |
| Condicion, medida y umbral | Ver matriz |
| Prueba, evidencia y semana | Ver matriz |
| Datos y operaciones | Tabla `destino_frecuente` (UNIQUE por usuario y etiqueta, sin distinguir mayusculas). Operaciones: `guardar` (devuelve id real), `buscarPorId` (null si no existe), `listarPorUsuario`. |
| Resultado semana 1 y pendientes | Probado: guardar, recuperar en conexion nueva, id inexistente, etiqueta repetida y usuario inexistente. Pendiente: servicio, seleccion por voz y calculo de ruta (semanas 2 y 3). |

## 3. Matriz RF-RNF
Los RNF se conservan con los identificadores del documento del segundo corte (RFN-01 a RFN-05). **RFN-06, RFN-07 y RFN-08 son nuevos**, derivados de la persistencia; **RFN-04 se ajusta** para aplicarse tambien a los datos personales guardados. Los umbrales son propuestos por el equipo.

| RNF | RF | ISO/IEC 25010:2023 | Condicion de prueba | Medida y umbral | Evidencia | Semana |
|---|---|---|---|---|---|---|
| RFN-01 | RF-10 | Eficiencia de desempeno / comportamiento temporal | Cambiar la sensibilidad sin reiniciar el pipeline | Alerta en menos de 300 ms (pipeline local 200 ms o menos, RF-09) | Mediciones en el telefono | 3 (pendiente) |
| RFN-03 | RF-10, RF-DF | Capacidad de interaccion / inclusividad (accesibilidad, NTC 5854) | Usar las pantallas con lector de pantalla y alto contraste | Todos los controles con etiqueta accesible y confirmacion por voz | Prueba manual con TalkBack y captura | 3 (pendiente) |
| RFN-04 (ajustado) | RF-10, RF-DF | Seguridad / confidencialidad (Ley 1581 de 2012) | Revisar esquema y datos de prueba | La contrasena solo se guarda como hash; direcciones solo locales; sin credenciales reales en el repositorio | `db/schema.sql`, `db/seed.sql` | 1 (revision) y 3 |
| RFN-06 (nuevo) | RF-10, RF-DF | Mantenibilidad / capacidad para ser probado | Probar los servicios con un repositorio simulado, sin base real | Una prueba de resultado valido y otra de rechazo o ausencia por servicio | `repositorios_memoria.dart` y prueba de contrato | Contrato en 1, pruebas de servicios en 2 |
| RFN-07 (nuevo) | RF-10, RF-DF | Fiabilidad / recuperabilidad | Guardar 10 destinos, cerrar la conexion y abrir una nueva | 10 de 10 recuperados (100 %) y configuracion identica | `test/persistencia_test.dart` | 1 |
| RFN-08 (nuevo) | RF-10, RF-DF | Eficiencia de desempeno / comportamiento temporal | 20 lecturas consecutivas de configuracion en la base de prueba, un cliente | Cada lectura en 50 ms o menos (unos 17 % del presupuesto de 300 ms de RFN-01) | `test/persistencia_test.dart` | 1 (datos) y 2 (API) |

## 4. Datos y persistencia
**Tablas** (`db/schema.sql`): `usuario`, `configuracion` (1:1 con usuario) y `destino_frecuente` (N:1 con usuario). Claves foraneas con borrado en cascada, restricciones CHECK de rango y UNIQUE (id_usuario, etiqueta).

**Cambios frente al modelo previo:** `usuario` sin `estado`; `configuracion` sin `distancia_alerta` (aparece en HU-11 pero no en RF-10); `modo_tonos` toma los valores `frecuencia_simple` y `espacializada`; `volumen_maestro` entre 50 y 95; se agrega `fecha_actualizacion`; `destino_frecuente` exige latitud y longitud; etiqueta unica por usuario sin distinguir mayusculas.

| Operacion del repositorio | RF | Para que se necesita |
|---|---|---|
| `RepositorioUsuarios.buscarPorId` | RF-10, RF-DF | Que negocio verifique que el usuario existe |
| `RepositorioConfiguracion.obtener` | RF-10 | Leer las preferencias vigentes (null si no hay) |
| `RepositorioConfiguracion.guardar` | RF-10 | Persistir las preferencias; rechaza valores invalidos |
| `RepositorioDestinos.guardar` | RF-DF | Persistir el destino y obtener su id real |
| `RepositorioDestinos.buscarPorId` | RF-DF | Recuperar el destino o representar su ausencia |
| `RepositorioDestinos.listarPorUsuario` | RF-DF | Mostrar los destinos del usuario |

**Separacion de capas.** El repositorio solo consulta y guarda; las reglas de negocio las aplica el servicio en la semana 2; las pantallas y endpoints no contienen SQL. **Transacciones:** cada operacion es una sola sentencia atomica y el repositorio es quien la confirma o revierte (SQLite). **Conexiones:** `BaseDatos` abre una conexion por archivo y quien la abre debe llamar a `cerrar()`; cada prueba abre y cierra la suya. **Errores:** valor fuera de rango = ERR-15; no se pudo guardar, duplicado o usuario inexistente = ERR-16.

## 5. Como repetir la verificacion
Requisitos: Flutter 3.47.8 y Dart 3.13.7; sqflite 2.4.5, path 1.9.1 y sqflite_common_ffi 2.4.5. No se necesita emulador ni credenciales.

```
cd app_vista
flutter pub get
flutter test test/persistencia_test.dart
```
**Estado inicial:** cada prueba crea un archivo SQLite temporal desde `db/schema.sql` y `db/seed.sql`: usuario 1 con configuracion (0.5, 1.2x, frecuencia simple, volumen 60) y destinos "Casa" y "Universidad"; usuario 2 sin configuracion ni destinos. **Resultado esperado:** 13 pruebas y el mensaje `All tests passed!`. **Evidencias:** captura de la terminal en `docs/evidencias/`.

Si falla con "Failed to load dynamic library sqlite3.dll" (Windows), descargar `sqlite3.dll` de sqlite.org y colocarlo en la carpeta `app_vista`.

## 6. Probado y pendiente
**Probado (semana 1):** lectura, escritura y persistencia real en conexion nueva; id inexistente; restricciones de rango, etiqueta unica y clave foranea; recuperabilidad (RFN-07) y tiempo de lectura (RFN-08); dobles en memoria para los servicios (RFN-06).
**Pendiente semana 2:** `ConfiguracionService` y servicio de destinos con sus reglas (RN-06, RN-14), contratos de API, pruebas de servicios con el repositorio simulado.
**Pendiente semana 3:** pantallas accesibles (RFN-03), aplicacion de la sensibilidad en caliente y medicion de latencia en el telefono (RFN-01), flujo completo.

import 'dart:io';

import 'package:app_vista/api/servidor_api.dart';
import 'package:app_vista/datos/base_datos.dart';
import 'package:app_vista/servicios/composicion.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Arranque de la API de VISTA (semana 14).
///
/// Variables de entorno:
///   PORT    puerto HTTP (por defecto 8080)
///   DB_PATH archivo SQLite (por defecto vista.db en la carpeta actual)
///
/// Uso: dart run bin/server.dart
Future<void> main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final puerto = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final rutaBd = Platform.environment['DB_PATH'] ?? 'vista.db';

  final esquema = File('db/schema.sql').readAsStringSync();
  final archivoSemilla = File('db/seed.sql');
  final semilla =
      archivoSemilla.existsSync() ? archivoSemilla.readAsStringSync() : null;

  // Quien abre la conexion la cierra: este proceso llama a cerrar() al salir.
  final baseDatos =
      await BaseDatos.abrir(rutaBd, esquemaSql: esquema, semillaSql: semilla);
  final api = ServidorApi(servicios: crearServicios(baseDatos));
  final servidor =
      await shelf_io.serve(api.handler, InternetAddress.anyIPv4, puerto);

  stdout.writeln('VISTA API escuchando en http://localhost:$puerto');
  stdout.writeln('Base de datos: $rutaBd');

  Future<void> detener(ProcessSignal senal) async {
    stdout.writeln('Cerrando servidor ($senal)...');
    await servidor.close(force: true);
    await baseDatos.cerrar();
    exit(0);
  }

  ProcessSignal.sigint.watch().listen(detener);
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen(detener);
  }
}

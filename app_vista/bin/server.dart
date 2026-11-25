import 'dart:io';

import 'package:app_vista/api/servidor_api.dart';
import 'package:app_vista/datos/base_datos_mysql.dart';
import 'package:app_vista/servicios/composicion.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Arranque de la API de VISTA conectada a MySQL.
///
/// Variables de entorno:
///   PORT    puerto HTTP (por defecto 8080)
///   MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE
///
/// Uso: dart run bin/server.dart
Future<void> main() async {
  final puerto = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final baseDatos = await BaseDatosMySql.conectar();
  final api = ServidorApi(servicios: crearServicios(baseDatos));
  final servidor = await shelf_io.serve(
    api.handler,
    InternetAddress.anyIPv4,
    puerto,
  );

  stdout.writeln('VISTA API escuchando en http://localhost:$puerto');
  stdout.writeln(
    'Base de datos MySQL: ${Platform.environment['MYSQL_DATABASE'] ?? 'vista'}',
  );

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

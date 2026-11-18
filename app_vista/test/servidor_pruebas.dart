import 'dart:io';

import 'package:app_vista/api/servidor_api.dart';
import 'package:app_vista/datos/base_datos.dart';
import 'package:app_vista/servicios/composicion.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Servidor HTTP y archivo SQLite aislados para las pruebas funcionales.
class ServidorPruebas {
  ServidorPruebas._({
    required this.directorio,
    required this.rutaBd,
    required this.baseDatos,
    required this.servidor,
  });

  final Directory directorio;
  final String rutaBd;
  final BaseDatos baseDatos;
  final HttpServer servidor;

  Uri get baseUri => Uri.parse('http://127.0.0.1:${servidor.port}');

  static Future<ServidorPruebas> iniciar() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final directorio = await Directory.systemTemp.createTemp('vista_api_');
    final rutaBd = '${directorio.path}${Platform.pathSeparator}vista_test.db';
    final esquema = await File('db/schema.sql').readAsString();
    final semilla = await File('db/seed.sql').readAsString();
    final baseDatos = await BaseDatos.abrir(
      rutaBd,
      esquemaSql: esquema,
      semillaSql: semilla,
    );
    final api = ServidorApi(servicios: crearServicios(baseDatos));
    final servidor = await shelf_io.serve(
      api.handler,
      InternetAddress.loopbackIPv4,
      0,
    );
    return ServidorPruebas._(
      directorio: directorio,
      rutaBd: rutaBd,
      baseDatos: baseDatos,
      servidor: servidor,
    );
  }

  Future<void> cerrar() async {
    await servidor.close(force: true);
    await baseDatos.cerrar();
    await directorio.delete(recursive: true);
  }
}

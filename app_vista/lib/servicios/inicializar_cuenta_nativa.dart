import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../datos/base_datos.dart';
import '../datos/repositorio_autenticacion_sqlite.dart';
import '../datos/repositorio_configuracion_sqlite.dart';
import '../datos/repositorio_usuarios_sqlite.dart';
import 'autenticacion_service.dart';
import 'configuracion_service.dart';
import 'servicios_cuenta.dart';

class ServiciosCuentaNativa implements ServiciosCuenta {
  ServiciosCuentaNativa({
    required this.baseDatos,
    required this.autenticacion,
    required this.configuracion,
  });

  final BaseDatos baseDatos;

  @override
  final AutenticacionService autenticacion;

  @override
  final ConfiguracionService configuracion;

  @override
  Future<void> cerrar() => baseDatos.cerrar();
}

Future<ServiciosCuenta?> inicializarServiciosCuenta() async {
  final esquema = await rootBundle.loadString('db/schema.sql');
  final ruta = p.join(await getDatabasesPath(), 'vista_persona.db');
  final baseDatos = await BaseDatos.abrir(ruta, esquemaSql: esquema);
  final usuarios = RepositorioUsuariosSqlite(baseDatos);
  return ServiciosCuentaNativa(
    baseDatos: baseDatos,
    autenticacion: AutenticacionService(
      repositorio: RepositorioAutenticacionSqlite(baseDatos),
    ),
    configuracion: ConfiguracionService(
      usuarios: usuarios,
      configuracion: RepositorioConfiguracionSqlite(baseDatos),
    ),
  );
}

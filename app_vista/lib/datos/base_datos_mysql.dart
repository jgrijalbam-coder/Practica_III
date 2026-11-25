import 'dart:io';

import 'package:mysql1/mysql1.dart';

/// Conexion del backend a la base de datos MySQL `vista`.
class BaseDatosMySql {
  BaseDatosMySql._(this.conn);

  final MySqlConnection conn;

  static Future<BaseDatosMySql> conectar() async {
    String variable(String nombre, String defecto) =>
        Platform.environment[nombre] ?? defecto;

    final conexion = await MySqlConnection.connect(
      ConnectionSettings(
        host: variable('MYSQL_HOST', '127.0.0.1'),
        port: int.tryParse(variable('MYSQL_PORT', '3306')) ?? 3306,
        user: variable('MYSQL_USER', 'root'),
        password: variable('MYSQL_PASSWORD', ''),
        db: variable('MYSQL_DATABASE', 'vista'),
      ),
    );
    return BaseDatosMySql._(conexion);
  }

  Future<void> cerrar() => conn.close();
}

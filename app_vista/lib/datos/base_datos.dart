import 'package:sqflite/sqflite.dart';

/// Duena de la conexion SQLite. Abre UNA conexion por archivo, activa las
/// claves foraneas y, solo si la base es nueva, ejecuta el esquema y la semilla.
/// Quien la abre es responsable de llamar a cerrar() para liberar la conexion.
class BaseDatos {
  BaseDatos._(this.db);

  final Database db;
  bool _abierta = true;

  static Future<BaseDatos> abrir(
    String ruta, {
    required String esquemaSql,
    String? semillaSql,
  }) async {
    final db = await openDatabase(
      ruta,
      version: 1,
      onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
      onCreate: (d, version) async {
        for (final s in dividirSql(esquemaSql)) {
          await d.execute(s);
        }
        if (semillaSql != null) {
          for (final s in dividirSql(semillaSql)) {
            await d.execute(s);
          }
        }
      },
    );
    return BaseDatos._(db);
  }

  Future<void> cerrar() async {
    if (!_abierta) return;
    _abierta = false;
    await db.close();
  }
}

/// Parte un script en sentencias (sin comentarios de linea). Los scripts no
/// deben tener ';' dentro de textos ni triggers.
List<String> dividirSql(String script) {
  final sinComentarios = script
      .split('\n')
      .where((linea) => !linea.trimLeft().startsWith('--'))
      .join('\n');
  return sinComentarios
      .split(';')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

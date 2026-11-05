import 'package:sqflite/sqflite.dart';
import 'base_datos.dart';
import 'modelos_datos.dart';
import 'repositorio_configuracion.dart';
import 'traduccion_errores_sqlite.dart';

/// Cada operacion es UNA sentencia SQL atomica: SQLite la confirma o la revierte.
/// Esta clase no contiene reglas de negocio; las reglas (RN-06, RN-14) las
/// aplicara el servicio en la semana 2 y las restricciones CHECK las refuerzan.
class RepositorioConfiguracionSqlite implements RepositorioConfiguracion {
  RepositorioConfiguracionSqlite(this._bd, {DateTime Function()? reloj})
      : _reloj = reloj ?? DateTime.now;

  final BaseDatos _bd;
  final DateTime Function() _reloj;

  static const _upsert = '''
INSERT INTO configuracion
  (id_usuario, sensibilidad, velocidad_voz, modo_tonos, volumen_maestro, fecha_actualizacion)
VALUES (?, ?, ?, ?, ?, ?)
ON CONFLICT(id_usuario) DO UPDATE SET
  sensibilidad = excluded.sensibilidad,
  velocidad_voz = excluded.velocidad_voz,
  modo_tonos = excluded.modo_tonos,
  volumen_maestro = excluded.volumen_maestro,
  fecha_actualizacion = excluded.fecha_actualizacion
''';

  @override
  Future<Configuracion?> obtener(int idUsuario) async {
    final filas = await _bd.db.query('configuracion',
        where: 'id_usuario = ?', whereArgs: [idUsuario], limit: 1);
    if (filas.isEmpty) return null;
    final f = filas.first;
    return Configuracion(
      idConfig: f['id_config'] as int,
      idUsuario: f['id_usuario'] as int,
      sensibilidad: (f['sensibilidad'] as num).toDouble(),
      velocidadVoz: (f['velocidad_voz'] as num).toDouble(),
      modoTonos: ModoTonos.desdeBd(f['modo_tonos'] as String),
      volumenMaestro: f['volumen_maestro'] as int,
    );
  }

  @override
  Future<Configuracion> guardar(Configuracion c) async {
    try {
      await _bd.db.execute(_upsert, [
        c.idUsuario,
        c.sensibilidad,
        c.velocidadVoz,
        c.modoTonos.valorBd,
        c.volumenMaestro,
        _reloj().toIso8601String(),
      ]);
    } on DatabaseException catch (e) {
      throw traducirErrorBd(e);
    }
    return (await obtener(c.idUsuario))!;
  }
}

import 'package:sqflite/sqflite.dart';
import 'base_datos.dart';
import 'modelos_datos.dart';
import 'repositorio_destinos.dart';
import 'traduccion_errores_sqlite.dart';

class RepositorioDestinosSqlite implements RepositorioDestinos {
  RepositorioDestinosSqlite(this._bd, {DateTime Function()? reloj})
      : _reloj = reloj ?? DateTime.now;

  final BaseDatos _bd;
  final DateTime Function() _reloj;

  DestinoFrecuente _desdeFila(Map<String, Object?> f) => DestinoFrecuente(
        idDestino: f['id_destino'] as int,
        idUsuario: f['id_usuario'] as int,
        etiqueta: f['etiqueta'] as String,
        direccion: f['direccion'] as String,
        latitud: (f['latitud'] as num).toDouble(),
        longitud: (f['longitud'] as num).toDouble(),
      );

  @override
  Future<DestinoFrecuente> guardar(DestinoFrecuente d) async {
    try {
      final id = await _bd.db.insert('destino_frecuente', {
        'id_usuario': d.idUsuario,
        'etiqueta': d.etiqueta,
        'direccion': d.direccion,
        'latitud': d.latitud,
        'longitud': d.longitud,
        'fecha_creacion': _reloj().toIso8601String(),
      });
      return DestinoFrecuente(
        idDestino: id,
        idUsuario: d.idUsuario,
        etiqueta: d.etiqueta,
        direccion: d.direccion,
        latitud: d.latitud,
        longitud: d.longitud,
      );
    } on DatabaseException catch (e) {
      throw traducirErrorBd(e);
    }
  }

  @override
  Future<DestinoFrecuente?> buscarPorId(int idDestino) async {
    final filas = await _bd.db.query('destino_frecuente',
        where: 'id_destino = ?', whereArgs: [idDestino], limit: 1);
    return filas.isEmpty ? null : _desdeFila(filas.first);
  }

  @override
  Future<List<DestinoFrecuente>> listarPorUsuario(int idUsuario) async {
    final filas = await _bd.db.query('destino_frecuente',
        where: 'id_usuario = ?', whereArgs: [idUsuario], orderBy: 'etiqueta COLLATE NOCASE');
    return filas.map(_desdeFila).toList();
  }
}

import 'base_datos.dart';
import 'modelos_datos.dart';
import 'repositorio_usuarios.dart';

class RepositorioUsuariosSqlite implements RepositorioUsuarios {
  RepositorioUsuariosSqlite(this._bd);
  final BaseDatos _bd;

  @override
  Future<Usuario?> buscarPorId(int idUsuario) async {
    final filas = await _bd.db.query('usuario',
        where: 'id_usuario = ?', whereArgs: [idUsuario], limit: 1);
    if (filas.isEmpty) return null;
    final f = filas.first;
    return Usuario(
      idUsuario: f['id_usuario'] as int,
      nombre: f['nombre'] as String,
      correo: f['correo'] as String,
    );
  }
}

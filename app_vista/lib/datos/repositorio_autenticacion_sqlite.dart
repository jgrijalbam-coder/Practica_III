import 'package:sqflite/sqflite.dart';

import 'base_datos.dart';
import 'modelos_datos.dart';
import 'repositorio_autenticacion.dart';

class RepositorioAutenticacionSqlite implements RepositorioAutenticacion {
  RepositorioAutenticacionSqlite(this._baseDatos);

  final BaseDatos _baseDatos;

  @override
  Future<CredencialesGuardadas?> buscarPorCorreo(String correo) async {
    final filas = await _baseDatos.db.query(
      'usuario',
      where: 'correo = ?',
      whereArgs: [correo],
      limit: 1,
    );
    if (filas.isEmpty) return null;
    final fila = filas.single;
    return CredencialesGuardadas(
      usuario: Usuario(
        idUsuario: fila['id_usuario'] as int,
        nombre: fila['nombre'] as String,
        correo: fila['correo'] as String,
      ),
      hash: fila['contrasena_hash'] as String,
    );
  }

  @override
  Future<Usuario> crearCuenta({
    required String nombre,
    required String correo,
    required String hashContrasena,
  }) async {
    return _baseDatos.db.transaction((tx) async {
      final ahora = DateTime.now().toIso8601String();
      final id = await tx.insert('usuario', {
        'nombre': nombre,
        'correo': correo,
        'contrasena_hash': hashContrasena,
        'fecha_registro': ahora,
      });
      await tx.insert('configuracion', {
        'id_usuario': id,
        'sensibilidad': 0.5,
        'velocidad_voz': 1.2,
        'modo_tonos': 'frecuencia_simple',
        'volumen_maestro': 60,
        'fecha_actualizacion': ahora,
      });
      return Usuario(idUsuario: id, nombre: nombre, correo: correo);
    });
  }
}

import 'package:sqflite/sqflite.dart';
import 'errores_persistencia.dart';

/// Convierte un error de SQLite en un error de persistencia de VISTA.
ErrorPersistencia traducirErrorBd(DatabaseException e) {
  final texto = e.toString();
  if (texto.contains('FOREIGN KEY constraint failed')) {
    return const UsuarioInexistenteError();
  }
  if (texto.contains('CHECK constraint failed')) {
    return const RestriccionVioladaError('ERR-15', 'Valor no permitido.');
  }
  if (texto.contains('UNIQUE constraint failed')) {
    return const RestriccionVioladaError('ERR-16', 'Ya existe un registro con ese valor.');
  }
  if (texto.contains('NOT NULL constraint failed')) {
    return const RestriccionVioladaError('ERR-16', 'Falta un dato obligatorio.');
  }
  return const ErrorPersistencia('ERR-16', 'No pude guardar los cambios.');
}

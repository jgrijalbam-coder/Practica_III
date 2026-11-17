import 'dart:io';

/// Registro de fallos internos del servidor. Al cliente solo se le devuelve un
/// mensaje generico; el detalle tecnico queda en la consola del servidor.
typedef RegistroErrores = void Function(
  String contexto,
  Object error,
  StackTrace pila,
);

void registrarEnConsola(String contexto, Object error, StackTrace pila) {
  stderr
      .writeln('[VISTA][$contexto] ${DateTime.now().toIso8601String()} $error');
  stderr.writeln(pila);
}

import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../dominio/excepciones_dominio.dart';

/// Convierte un identificador de ruta en entero positivo.
int leerIdDeRuta(String texto) {
  final id = int.tryParse(texto);
  if (id == null || id <= 0) {
    throw const ValidacionError(
      'El identificador debe ser un entero positivo.',
    );
  }
  return id;
}

/// Lee un objeto JSON. Cuerpos mal formados o no objeto se consideran 400.
Future<Map<String, Object?>> leerCuerpoJson(Request peticion) async {
  final texto = await peticion.readAsString();
  Object? decodificado;
  try {
    decodificado = jsonDecode(texto);
  } on FormatException {
    throw const ValidacionError('El cuerpo debe contener JSON valido.');
  }
  if (decodificado is! Map) {
    throw const ValidacionError('El cuerpo JSON debe ser un objeto.');
  }
  final resultado = <String, Object?>{};
  for (final entrada in decodificado.entries) {
    if (entrada.key is! String) {
      throw const ValidacionError('Las claves del JSON deben ser texto.');
    }
    resultado[entrada.key as String] = entrada.value;
  }
  return resultado;
}

String? leerTextoOpcional(Map<String, Object?> json, String campo) {
  if (!json.containsKey(campo)) return null;
  final valor = json[campo];
  if (valor is! String) {
    throw ValidacionError('El campo "$campo" debe ser texto.');
  }
  return valor;
}

double? leerDoubleOpcional(Map<String, Object?> json, String campo) {
  if (!json.containsKey(campo)) return null;
  final valor = json[campo];
  if (valor is! num || !valor.toDouble().isFinite) {
    throw ValidacionError('El campo "$campo" debe ser un numero finito.');
  }
  return valor.toDouble();
}

int? leerEnteroOpcional(Map<String, Object?> json, String campo) {
  if (!json.containsKey(campo)) return null;
  final valor = json[campo];
  if (valor is! int) {
    throw ValidacionError('El campo "$campo" debe ser un entero.');
  }
  return valor;
}

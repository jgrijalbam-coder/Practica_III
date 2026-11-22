import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/helpers.dart'
    show constantTimeBytesEquality, randomBytes;

/// Argon2id con sal aleatoria por cuenta; nunca guarda la contraseña original.
class HasheadorContrasenas {
  static const _memoria = 19456;
  static const _iteraciones = 2;
  static const _paralelismo = 1;
  static const _longitudHash = 32;

  final Argon2id _algoritmo = Argon2id(
    memory: _memoria,
    iterations: _iteraciones,
    parallelism: _paralelismo,
    hashLength: _longitudHash,
  );

  Future<String> crearHash(String contrasena) async {
    final sal = randomBytes(16);
    final secreto = await _algoritmo.deriveKeyFromPassword(
      password: contrasena,
      nonce: sal,
    );
    final hash = await secreto.extractBytes();
    return 'argon2id\$$_memoria\$$_iteraciones\$$_paralelismo\$'
        '${base64UrlEncode(sal)}\$${base64UrlEncode(hash)}';
  }

  Future<bool> verificar(String contrasena, String almacenado) async {
    final partes = almacenado.split(r'$');
    if (partes.length != 6 || partes.first != 'argon2id') return false;
    final memoria = int.tryParse(partes[1]);
    final iteraciones = int.tryParse(partes[2]);
    final paralelismo = int.tryParse(partes[3]);
    if (memoria == null || iteraciones == null || paralelismo == null) {
      return false;
    }
    try {
      final algoritmo = Argon2id(
        memory: memoria,
        iterations: iteraciones,
        parallelism: paralelismo,
        hashLength: _longitudHash,
      );
      final esperado = base64Url.decode(partes[5]);
      final derivado = await algoritmo.deriveKeyFromPassword(
        password: contrasena,
        nonce: base64Url.decode(partes[4]),
      );
      return constantTimeBytesEquality.equals(
        await derivado.extractBytes(),
        esperado,
      );
    } on FormatException {
      return false;
    }
  }
}

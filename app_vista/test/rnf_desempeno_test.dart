import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'servidor_pruebas.dart';

void main() {
  test('RFN-08: 20 lecturas HTTP de configuracion, cada una <= 50 ms', () async {
    final entorno = await ServidorPruebas.iniciar();
    final cliente = http.Client();
    final tiemposMs = <double>[];
    var respuestasCumplidas = 0;
    try {
      for (var indice = 1; indice <= 20; indice++) {
        final cronometro = Stopwatch()..start();
        final respuesta = await cliente.get(
          entorno.baseUri.resolve('/api/usuarios/1/configuracion'),
        );
        cronometro.stop();
        final milisegundos = cronometro.elapsedMicroseconds / 1000;
        tiemposMs.add(milisegundos);
        final cumple =
            respuesta.statusCode == HttpStatus.ok && milisegundos <= 50;
        if (cumple) respuestasCumplidas++;
        // ignore: avoid_print
        print(
          'RFN-08 lectura $indice: ${milisegundos.toStringAsFixed(3)} ms, '
          'HTTP ${respuesta.statusCode}, ${cumple ? "cumple" : "no cumple"}',
        );
      }
      // ignore: avoid_print
      print(
        'RFN-08: $respuestasCumplidas/20 cumplen el umbral individual de 50 ms.',
      );
      expect(tiemposMs, hasLength(20));
      expect(
        respuestasCumplidas,
        20,
        reason: 'Cada respuesta completa del cliente debe tardar <= 50 ms.',
      );
    } finally {
      cliente.close();
      await entorno.cerrar();
    }
  });
}

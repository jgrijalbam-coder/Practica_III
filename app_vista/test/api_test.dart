import 'dart:convert';

import 'package:app_vista/datos/base_datos.dart';
import 'package:app_vista/datos/repositorio_configuracion_sqlite.dart';
import 'package:app_vista/datos/repositorio_destinos_sqlite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'servidor_pruebas.dart';

void main() {
  late ServidorPruebas entorno;
  late http.Client cliente;

  setUp(() async {
    entorno = await ServidorPruebas.iniciar();
    cliente = http.Client();
  });

  tearDown(() async {
    cliente.close();
    await entorno.cerrar();
  });

  Map<String, dynamic> decodificar(http.Response respuesta) =>
      jsonDecode(respuesta.body) as Map<String, dynamic>;

  Future<int> contarConfiguraciones() async =>
      (await entorno.baseDatos.db.rawQuery(
            'SELECT COUNT(*) AS total FROM configuracion',
          )).single['total']!
          as int;

  Future<int> contarDestinos() async =>
      (await entorno.baseDatos.db.rawQuery(
            'SELECT COUNT(*) AS total FROM destino_frecuente',
          )).single['total']!
          as int;

  test('RF-10 GET devuelve configuracion y no modifica la BD', () async {
    final configuracionesAntes = await contarConfiguraciones();
    final destinosAntes = await contarDestinos();

    final respuesta = await cliente.get(
      entorno.baseUri.resolve('/api/usuarios/1/configuracion'),
    );

    expect(respuesta.statusCode, 200);
    expect(decodificar(respuesta)['sensibilidad'], 0.5);
    expect(decodificar(respuesta)['modo_tonos'], 'frecuencia_simple');
    expect(await contarConfiguraciones(), configuracionesAntes);
    expect(await contarDestinos(), destinosAntes);
  });

  test('RF-10 PUT persiste en una conexion nueva', () async {
    final respuesta = await cliente.put(
      entorno.baseUri.resolve('/api/usuarios/1/configuracion'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'sensibilidad': 0.7,
        'velocidad_voz': 1.5,
        'modo_tonos': 'espacializada',
        'volumen_maestro': 80,
      }),
    );

    expect(respuesta.statusCode, 200);
    final otraConexion = await BaseDatos.abrir(entorno.rutaBd, esquemaSql: '');
    try {
      final guardada = await RepositorioConfiguracionSqlite(otraConexion)
          .obtener(1);
      expect(guardada!.sensibilidad, 0.7);
      expect(guardada.velocidadVoz, 1.5);
      expect(guardada.volumenMaestro, 80);
    } finally {
      await otraConexion.cerrar();
    }
  });

  test('RF-10 JSON invalido, rango invalido y configuracion ausente', () async {
    final antes = await contarConfiguraciones();
    final rango = await cliente.put(
      entorno.baseUri.resolve('/api/usuarios/1/configuracion'),
      headers: {'content-type': 'application/json'},
      body: '{"sensibilidad":0.6}',
    );
    final jsonMalformado = await cliente.put(
      entorno.baseUri.resolve('/api/usuarios/1/configuracion'),
      headers: {'content-type': 'application/json'},
      body: '{no-json',
    );
    final ausente = await cliente.get(
      entorno.baseUri.resolve('/api/usuarios/2/configuracion'),
    );

    expect(rango.statusCode, 400);
    expect(decodificar(rango).keys, contains('detail'));
    expect(jsonMalformado.statusCode, 400);
    expect(ausente.statusCode, 404);
    expect(await contarConfiguraciones(), antes);
  });

  test(
    'RF-14 POST devuelve id real persistido en una conexion nueva',
    () async {
      final respuesta = await cliente.post(
        entorno.baseUri.resolve('/api/usuarios/1/destinos'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'etiqueta': 'Parque',
          'latitud': 4.62,
          'longitud': -74.08,
        }),
      );

      expect(respuesta.statusCode, 201);
      final json = decodificar(respuesta);
      expect(json['id_destino'], isA<int>());
      expect(json['id_usuario'], 1);
      final otraConexion = await BaseDatos.abrir(
        entorno.rutaBd,
        esquemaSql: '',
      );
      try {
        final guardado = await RepositorioDestinosSqlite(otraConexion)
            .buscarPorId(json['id_destino'] as int);
        expect(guardado!.etiqueta, 'Parque');
        expect(guardado.latitud, 4.62);
      } finally {
        await otraConexion.cerrar();
      }
    },
  );

  test('RF-14 rechazo no crea registros; ausencias e ids invalidos', () async {
    final antes = await contarDestinos();
    final duplicado = await cliente.post(
      entorno.baseUri.resolve('/api/usuarios/1/destinos'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'etiqueta': 'cASA',
        'latitud': 4.61,
        'longitud': -74.08,
      }),
    );
    final coordenada = await cliente.post(
      entorno.baseUri.resolve('/api/usuarios/1/destinos'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'etiqueta': 'Lejos',
        'latitud': 91,
        'longitud': -74.08,
      }),
    );
    final usuarioAusente = await cliente.post(
      entorno.baseUri.resolve('/api/usuarios/999/destinos'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'etiqueta': 'Otro',
        'latitud': 4.61,
        'longitud': -74.08,
      }),
    );
    final idInvalido = await cliente.get(
      entorno.baseUri.resolve('/api/destinos/0'),
    );

    expect(duplicado.statusCode, 409);
    expect(coordenada.statusCode, 400);
    expect(usuarioAusente.statusCode, 404);
    expect(idInvalido.statusCode, 400);
    expect(await contarDestinos(), antes);
  });

  test('RF-14 buscar, listar y listar vacio', () async {
    final encontrado = await cliente.get(
      entorno.baseUri.resolve('/api/destinos/1'),
    );
    final noEncontrado = await cliente.get(
      entorno.baseUri.resolve('/api/destinos/999'),
    );
    final lista = await cliente.get(
      entorno.baseUri.resolve('/api/usuarios/1/destinos'),
    );
    final listaVacia = await cliente.get(
      entorno.baseUri.resolve('/api/usuarios/2/destinos'),
    );
    final usuarioAusente = await cliente.get(
      entorno.baseUri.resolve('/api/usuarios/999/destinos'),
    );

    expect(encontrado.statusCode, 200);
    expect(decodificar(encontrado)['id_destino'], 1);
    expect(noEncontrado.statusCode, 404);
    expect(jsonDecode(lista.body), hasLength(2));
    expect(lista.statusCode, 200);
    expect(jsonDecode(listaVacia.body), isEmpty);
    expect(listaVacia.statusCode, 200);
    expect(usuarioAusente.statusCode, 404);
  });
}

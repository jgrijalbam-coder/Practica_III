import 'dart:io';

import 'package:app_vista/datos/base_datos.dart';
import 'package:app_vista/datos/errores_persistencia.dart';
import 'package:app_vista/datos/modelos_datos.dart';
import 'package:app_vista/datos/repositorio_configuracion_sqlite.dart';
import 'package:app_vista/datos/repositorio_destinos_sqlite.dart';
import 'package:app_vista/datos/repositorio_usuarios_sqlite.dart';
import 'package:app_vista/datos/repositorios_memoria.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<ErrorPersistencia> capturar(Future<Object?> Function() accion) async {
  try {
    await accion();
  } on ErrorPersistencia catch (e) {
    return e;
  }
  fail('Se esperaba un ErrorPersistencia y no se lanzo.');
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final esquema = File('db/schema.sql').readAsStringSync();
  final semilla = File('db/seed.sql').readAsStringSync();

  late Directory tmp;
  late String ruta;
  final abiertas = <BaseDatos>[];

  Future<BaseDatos> abrir() async {
    final bd = await BaseDatos.abrir(ruta, esquemaSql: esquema, semillaSql: semilla);
    abiertas.add(bd);
    return bd;
  }

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('vista_bd_');
    ruta = '${tmp.path}${Platform.pathSeparator}vista_test.db';
  });

  tearDown(() async {
    for (final b in abiertas) {
      await b.cerrar();
    }
    abiertas.clear();
    try {
      tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('estado inicial conocido', () async {
    final bd = await abrir();
    expect((await RepositorioUsuariosSqlite(bd).buscarPorId(1))!.correo, 'usuario1@vista.test');
    final c = (await RepositorioConfiguracionSqlite(bd).obtener(1))!;
    expect(c.sensibilidad, 0.5);
    expect(c.velocidadVoz, 1.2);
    expect(c.modoTonos, ModoTonos.frecuenciaSimple);
    expect(c.volumenMaestro, 60);
    expect((await RepositorioDestinosSqlite(bd).listarPorUsuario(1)).length, 2);
  });

  test('RF-10: guardar configuracion persiste en una conexion nueva', () async {
    var bd = await abrir();
    await RepositorioConfiguracionSqlite(bd).guardar(const Configuracion(
      idUsuario: 1,
      sensibilidad: 0.7,
      velocidadVoz: 1.5,
      modoTonos: ModoTonos.espacializada,
      volumenMaestro: 80,
    ));
    await bd.cerrar();

    bd = await abrir(); // conexion nueva sobre el mismo archivo
    final c = (await RepositorioConfiguracionSqlite(bd).obtener(1))!;
    expect(c.sensibilidad, 0.7);
    expect(c.velocidadVoz, 1.5);
    expect(c.modoTonos, ModoTonos.espacializada);
    expect(c.volumenMaestro, 80);
  });

  test('RF-10: usuario sin configuracion o inexistente devuelve null', () async {
    final repo = RepositorioConfiguracionSqlite(await abrir());
    expect(await repo.obtener(2), isNull);
    expect(await repo.obtener(999), isNull);
  });

  test('RF-10: guardar para un usuario inexistente lanza UsuarioInexistenteError', () async {
    final repo = RepositorioConfiguracionSqlite(await abrir());
    final error = await capturar(() => repo.guardar(const Configuracion(idUsuario: 999)));
    expect(error, isA<UsuarioInexistenteError>());
  });

  test('RF-10: valores fuera de rango se rechazan y se conserva el anterior', () async {
    final repo = RepositorioConfiguracionSqlite(await abrir());
    final invalidas = [
      const Configuracion(idUsuario: 1, sensibilidad: 0.6),
      const Configuracion(idUsuario: 1, velocidadVoz: 2.5),
      const Configuracion(idUsuario: 1, volumenMaestro: 40),
      const Configuracion(idUsuario: 1, volumenMaestro: 99),
    ];
    for (final invalida in invalidas) {
      final error = await capturar(() => repo.guardar(invalida));
      expect(error, isA<RestriccionVioladaError>());
      expect(error.codigo, 'ERR-15');
    }
    final c = (await repo.obtener(1))!;
    expect(c.sensibilidad, 0.5);
    expect(c.velocidadVoz, 1.2);
    expect(c.volumenMaestro, 60);
  });

  test('RF-DF: guardar devuelve id real y persiste en una conexion nueva', () async {
    var bd = await abrir();
    final guardado = await RepositorioDestinosSqlite(bd).guardar(const DestinoFrecuente(
      idUsuario: 1,
      etiqueta: 'Trabajo',
      direccion: 'Direccion de prueba 3, Bogota',
      latitud: 4.65,
      longitud: -74.1,
    ));
    expect(guardado.idDestino, greaterThan(2));
    await bd.cerrar();

    bd = await abrir();
    final leido = await RepositorioDestinosSqlite(bd).buscarPorId(guardado.idDestino!);
    expect(leido, isNotNull);
    expect(leido!.etiqueta, 'Trabajo');
    expect(leido.latitud, 4.65);
  });

  test('RF-DF: buscar un id inexistente devuelve null', () async {
    final repo = RepositorioDestinosSqlite(await abrir());
    expect(await repo.buscarPorId(9999), isNull);
  });

  test('RF-DF: etiqueta repetida (sin distinguir mayusculas) y usuario inexistente se rechazan', () async {
    final repo = RepositorioDestinosSqlite(await abrir());
    final duplicada = await capturar(() => repo.guardar(const DestinoFrecuente(
          idUsuario: 1,
          etiqueta: 'casa',
          direccion: 'Otra direccion',
          latitud: 4.6,
          longitud: -74.0,
        )));
    expect(duplicada, isA<RestriccionVioladaError>());

    final huerfano = await capturar(() => repo.guardar(const DestinoFrecuente(
          idUsuario: 999,
          etiqueta: 'Nuevo',
          direccion: 'Direccion',
          latitud: 4.6,
          longitud: -74.0,
        )));
    expect(huerfano, isA<UsuarioInexistenteError>());
  });

  test('RF-DF: listar devuelve los destinos del usuario ordenados por etiqueta', () async {
    final repo = RepositorioDestinosSqlite(await abrir());
    final u1 = await repo.listarPorUsuario(1);
    expect(u1.map((d) => d.etiqueta).toList(), ['Casa', 'Universidad']);
    expect(await repo.listarPorUsuario(2), isEmpty);
  });

  test('Integridad: borrar un usuario elimina su configuracion y sus destinos', () async {
    final bd = await abrir();
    await bd.db.delete('usuario', where: 'id_usuario = ?', whereArgs: [1]);
    expect(await RepositorioConfiguracionSqlite(bd).obtener(1), isNull);
    expect(await RepositorioDestinosSqlite(bd).listarPorUsuario(1), isEmpty);
  });

  test('RFN-07 (recuperabilidad): 10 destinos guardados se recuperan 10/10', () async {
    var bd = await abrir();
    var repo = RepositorioDestinosSqlite(bd);
    for (var i = 1; i <= 10; i++) {
      await repo.guardar(DestinoFrecuente(
        idUsuario: 2,
        etiqueta: 'Destino $i',
        direccion: 'Direccion $i',
        latitud: 4.0 + i / 100,
        longitud: -74.0,
      ));
    }
    await bd.cerrar();

    bd = await abrir();
    repo = RepositorioDestinosSqlite(bd);
    expect((await repo.listarPorUsuario(2)).length, 10);
  });

  test('RFN-08 (tiempo): 20 lecturas consecutivas de configuracion, cada una <= 50 ms', () async {
    final repo = RepositorioConfiguracionSqlite(await abrir());
    await repo.obtener(1); // calentamiento
    for (var i = 0; i < 20; i++) {
      final cronometro = Stopwatch()..start();
      await repo.obtener(1);
      cronometro.stop();
      expect(cronometro.elapsedMilliseconds, lessThanOrEqualTo(50));
    }
  });

  test('RFN-06 (testabilidad): los dobles en memoria cumplen el contrato', () async {
    final config = RepositorioConfiguracionMemoria(usuariosExistentes: [1]);
    expect(await config.obtener(1), isNull);
    final guardada = await config.guardar(const Configuracion(idUsuario: 1, sensibilidad: 0.4));
    expect(guardada.idConfig, isNotNull);
    expect((await config.obtener(1))!.sensibilidad, 0.4);
    expect(await capturar(() => config.guardar(const Configuracion(idUsuario: 9))),
        isA<UsuarioInexistenteError>());

    final destinos = RepositorioDestinosMemoria(usuariosExistentes: [1]);
    final d = await destinos.guardar(const DestinoFrecuente(
        idUsuario: 1, etiqueta: 'Casa', direccion: 'X', latitud: 4.0, longitud: -74.0));
    expect((await destinos.buscarPorId(d.idDestino!))!.etiqueta, 'Casa');
    expect(await destinos.buscarPorId(999), isNull);
  });
}

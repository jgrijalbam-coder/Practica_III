import 'package:app_vista/datos/modelos_datos.dart';
import 'package:app_vista/dominio/excepciones_dominio.dart';
import 'package:app_vista/dominio/reglas_configuracion.dart';
import 'package:app_vista/servicios/configuracion_service.dart';
import 'package:app_vista/servicios/destinos_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_espia.dart';

/// Prueba complementaria de testabilidad: los servicios se prueban con dobles en
/// memoria, SIN abrir ninguna conexion SQLite. Por servicio hay un caso valido
/// y un caso de rechazo/ausencia, y se verifica que en el rechazo no se escribe.

Future<ErrorDominio> capturarDominio(Future<Object?> Function() accion) async {
  try {
    await accion();
  } on ErrorDominio catch (e) {
    return e;
  }
  fail('Se esperaba un ErrorDominio y no se lanzo.');
}

void main() {
  group('ConfiguracionService (RF-10)', () {
    late EspiaUsuarios usuarios;
    late EspiaConfiguracion configuracion;
    late ConfiguracionService servicio;

    setUp(() {
      usuarios = EspiaUsuarios(existentes: [1, 2]);
      configuracion = EspiaConfiguracion();
      servicio =
          ConfiguracionService(usuarios: usuarios, configuracion: configuracion);
    });

    test('guarda una configuracion valida y la devuelve persistida', () async {
      final guardada = await servicio.guardar(
        1,
        const DatosConfiguracion(
          sensibilidad: 0.7,
          velocidadVoz: 1.5,
          modoTonos: ModoTonos.espacializada,
          volumenMaestro: 80,
        ),
      );

      expect(guardada.idUsuario, 1);
      expect(guardada.sensibilidad, 0.7);
      expect(guardada.velocidadVoz, 1.5);
      expect(guardada.modoTonos, ModoTonos.espacializada);
      expect(guardada.volumenMaestro, 80);
      expect(guardada.idConfig, isNotNull);
      // Una sola escritura y una lectura de confirmacion.
      expect(configuracion.llamadasGuardar, 1);
      expect(configuracion.llamadasObtener, 1);
      expect(configuracion.actual!.sensibilidad, 0.7);
    });

    test('rechaza una sensibilidad fuera de rango sin escribir', () async {
      final error = await capturarDominio(
        () => servicio.guardar(1, const DatosConfiguracion(sensibilidad: 0.6)),
      );

      expect(error, isA<ValidacionError>());
      expect(error.codigo, 'ERR-15');
      expect(configuracion.llamadasGuardar, 0, reason: 'no debe escribir');
      expect(configuracion.llamadasObtener, 0);
      expect(configuracion.actual, isNull);
    });

    test('rechaza velocidad y volumen fuera de rango sin escribir', () async {
      final casos = [
        const DatosConfiguracion(velocidadVoz: 2.5),
        const DatosConfiguracion(velocidadVoz: 0.5),
        const DatosConfiguracion(volumenMaestro: 40),
        const DatosConfiguracion(volumenMaestro: 99),
      ];
      for (final datos in casos) {
        final error = await capturarDominio(() => servicio.guardar(1, datos));
        expect(error, isA<ValidacionError>());
      }
      expect(configuracion.llamadasGuardar, 0);
    });

    test('rechaza un usuario inexistente sin escribir', () async {
      final error = await capturarDominio(
        () => servicio.guardar(999, const DatosConfiguracion()),
      );

      expect(error, isA<UsuarioNoEncontrado>());
      expect(configuracion.llamadasGuardar, 0);
      expect(usuarios.llamadasBuscarPorId, 1);
    });

    test('obtener solo lee: no invoca guardar', () async {
      await servicio.guardar(1, const DatosConfiguracion(sensibilidad: 0.4));
      final escriturasAntes = configuracion.llamadasGuardar;
      final lecturasAntes = configuracion.llamadasObtener;

      final leida = await servicio.obtener(1);

      expect(leida.sensibilidad, 0.4);
      expect(configuracion.llamadasGuardar, escriturasAntes);
      expect(configuracion.llamadasObtener, lecturasAntes + 1);
    });

    test('usuario sin configuracion -> ConfiguracionNoEncontrada sin escribir',
        () async {
      final error = await capturarDominio(() => servicio.obtener(2));

      expect(error, isA<ConfiguracionNoEncontrada>());
      expect(configuracion.llamadasObtener, 1);
      expect(configuracion.llamadasGuardar, 0);
    });

    test('id no positivo -> ValidacionError sin tocar la base', () async {
      final error = await capturarDominio(() => servicio.obtener(0));

      expect(error, isA<ValidacionError>());
      expect(usuarios.llamadasBuscarPorId, 0);
      expect(configuracion.llamadasObtener, 0);
    });
  });

  group('DestinosService (RF-14)', () {
    late EspiaUsuarios usuarios;
    late EspiaDestinos destinos;
    late DestinosService servicio;

    setUp(() {
      usuarios = EspiaUsuarios(existentes: [1, 2]);
      destinos = EspiaDestinos();
      servicio = DestinosService(usuarios: usuarios, destinos: destinos);
    });

    test('guarda un destino valido y devuelve el id real', () async {
      final guardado =
          await servicio.guardar(1, '  Casa  ', 4.6097, -74.0817);

      expect(guardado.idDestino, 1);
      expect(guardado.idUsuario, 1);
      expect(guardado.etiqueta, 'Casa', reason: 'se recorta la etiqueta');
      expect(guardado.latitud, 4.6097);
      expect(guardado.longitud, -74.0817);
      expect(guardado.direccion, isNotEmpty);
      expect(destinos.llamadasGuardar, 1);
      expect(destinos.guardados.length, 1);
    });

    test('etiqueta duplicada -> EtiquetaDuplicada y no crece la coleccion',
        () async {
      await servicio.guardar(1, 'Casa', 4.6, -74.0);
      destinos.rechazarPorEtiquetaDuplicada = true;

      final error =
          await capturarDominio(() => servicio.guardar(1, 'casa', 4.7, -74.1));

      expect(error, isA<EtiquetaDuplicada>());
      expect(error.codigo, 'ERR-16');
      expect(destinos.guardados.length, 1, reason: 'no debe crear otro destino');
      expect(destinos.llamadasGuardar, 2);
    });

    test('etiqueta vacia o coordenadas fuera de rango no escriben', () async {
      final casos = <Future<Object?> Function()>[
        () => servicio.guardar(1, '   ', 4.6, -74.0),
        () => servicio.guardar(1, 'Norte', 91, -74.0),
        () => servicio.guardar(1, 'Sur', -91, -74.0),
        () => servicio.guardar(1, 'Este', 4.6, 181),
        () => servicio.guardar(1, 'Oeste', 4.6, -181),
      ];
      for (final caso in casos) {
        final error = await capturarDominio(caso);
        expect(error, isA<ValidacionError>());
      }
      expect(destinos.llamadasGuardar, 0);
      expect(destinos.guardados, isEmpty);
    });

    test('usuario inexistente -> UsuarioNoEncontrado sin escribir', () async {
      final error =
          await capturarDominio(() => servicio.guardar(999, 'Casa', 4.6, -74.0));

      expect(error, isA<UsuarioNoEncontrado>());
      expect(destinos.llamadasGuardar, 0);
    });

    test('buscarPorId existente solo lee', () async {
      final guardado = await servicio.guardar(1, 'Casa', 4.6, -74.0);
      final escriturasAntes = destinos.llamadasGuardar;

      final leido = await servicio.buscarPorId(guardado.idDestino!);

      expect(leido.etiqueta, 'Casa');
      expect(destinos.llamadasGuardar, escriturasAntes);
    });

    test('buscarPorId ausente -> DestinoNoEncontrado', () async {
      final error = await capturarDominio(() => servicio.buscarPorId(99));

      expect(error, isA<DestinoNoEncontrado>());
      expect(destinos.llamadasBuscarPorId, 1);
      expect(destinos.llamadasGuardar, 0);
    });

    test('listarPorUsuario vacia es valida y solo lee', () async {
      final lista = await servicio.listarPorUsuario(2);

      expect(lista, isEmpty);
      expect(destinos.llamadasListarPorUsuario, 1);
      expect(destinos.llamadasGuardar, 0);
    });

    test('listarPorUsuario de un usuario inexistente -> UsuarioNoEncontrado',
        () async {
      final error = await capturarDominio(() => servicio.listarPorUsuario(999));

      expect(error, isA<UsuarioNoEncontrado>());
      expect(destinos.llamadasListarPorUsuario, 0);
    });
  });
}

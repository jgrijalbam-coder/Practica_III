import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../datos/modelos_datos.dart';
import '../datos/errores_persistencia.dart';
import '../datos/repositorio_configuracion.dart';
import '../datos/repositorio_destinos.dart';
import '../datos/repositorio_usuarios.dart';
import 'autenticacion_service.dart';
import 'configuracion_service.dart';
import 'destinos_service.dart';
import 'servicios_cuenta.dart';

/// Servicios de cuenta de Flutter. La aplicacion usa HTTP; solo el backend
/// abre conexiones a MySQL.
class ServiciosCuentaHttp implements ServiciosCuenta {
  ServiciosCuentaHttp._(Uri baseUri, http.Client cliente)
    : _cliente = cliente,
      autenticacion = AutenticacionHttp(baseUri, cliente),
      configuracion = ConfiguracionService(
        usuarios: RepositorioUsuariosHttp(baseUri, cliente),
        configuracion: RepositorioConfiguracionHttp(baseUri, cliente),
      ),
      destinos = DestinosService(
        usuarios: RepositorioUsuariosHttp(baseUri, cliente),
        destinos: RepositorioDestinosHttp(baseUri, cliente),
      );

  final http.Client _cliente;

  @override
  final ServicioAutenticacion autenticacion;

  @override
  final ConfiguracionService configuracion;

  @override
  final DestinosService destinos;

  @override
  Future<void> cerrar() async => _cliente.close();

  static ServiciosCuentaHttp crear({Uri? baseUri}) =>
      ServiciosCuentaHttp._(baseUri ?? _uriApiPorDefecto(), http.Client());
}

Uri _uriApiPorDefecto() {
  const configurada = String.fromEnvironment('VISTA_API_URL');
  if (configurada.isNotEmpty) return Uri.parse(configurada);
  return Uri.parse(
    defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8080'
        : 'http://localhost:8080',
  );
}

class AutenticacionHttp implements ServicioAutenticacion {
  AutenticacionHttp(this.baseUri, this.cliente);
  final Uri baseUri;
  final http.Client cliente;

  @override
  Future<Usuario> registrar({
    required String nombre,
    required String correo,
    required String contrasena,
  }) => _enviar('/api/auth/register', {
    'nombre': nombre,
    'correo': correo,
    'contrasena': contrasena,
  });

  @override
  Future<Usuario> iniciarSesion({
    required String correo,
    required String contrasena,
  }) =>
      _enviar('/api/auth/login', {'correo': correo, 'contrasena': contrasena});

  Future<Usuario> _enviar(String ruta, Map<String, Object?> datos) async {
    final respuesta = await cliente.post(
      baseUri.resolve(ruta),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(datos),
    );
    final cuerpo = _decodificar(respuesta.body);
    if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
      throw ErrorAutenticacion(
        cuerpo['detail'] as String? ?? 'No se pudo conectar con VISTA.',
      );
    }
    return Usuario(
      idUsuario: (cuerpo['id_usuario'] as num).toInt(),
      nombre: cuerpo['nombre'] as String,
      correo: cuerpo['correo'] as String,
    );
  }
}

class RepositorioUsuariosHttp implements RepositorioUsuarios {
  RepositorioUsuariosHttp(this.baseUri, this.cliente);
  final Uri baseUri;
  final http.Client cliente;

  @override
  Future<Usuario?> buscarPorId(int idUsuario) async {
    final respuesta = await cliente.get(
      baseUri.resolve('/api/usuarios/$idUsuario'),
    );
    if (respuesta.statusCode == 404) return null;
    final cuerpo = _decodificar(respuesta.body);
    if (respuesta.statusCode != 200) {
      throw StateError(
        cuerpo['detail'] as String? ?? 'Error consultando usuario.',
      );
    }
    return Usuario(
      idUsuario: (cuerpo['id_usuario'] as num).toInt(),
      nombre: cuerpo['nombre'] as String,
      correo: cuerpo['correo'] as String,
    );
  }
}

class RepositorioConfiguracionHttp implements RepositorioConfiguracion {
  RepositorioConfiguracionHttp(this.baseUri, this.cliente);
  final Uri baseUri;
  final http.Client cliente;

  @override
  Future<Configuracion?> obtener(int idUsuario) async {
    final respuesta = await cliente.get(
      baseUri.resolve('/api/usuarios/$idUsuario/configuracion'),
    );
    if (respuesta.statusCode == 404) return null;
    final cuerpo = _decodificar(respuesta.body);
    if (respuesta.statusCode != 200) {
      throw StateError(
        cuerpo['detail'] as String? ?? 'Error consultando configuración.',
      );
    }
    return Configuracion(
      idUsuario: idUsuario,
      sensibilidad: (cuerpo['sensibilidad'] as num).toDouble(),
      velocidadVoz: (cuerpo['velocidad_voz'] as num).toDouble(),
      modoTonos: ModoTonos.desdeBd(cuerpo['modo_tonos'] as String),
      volumenMaestro: (cuerpo['volumen_maestro'] as num).toInt(),
      fechaActualizacion: DateTime.tryParse(
        cuerpo['fecha_actualizacion']?.toString() ?? '',
      ),
    );
  }

  @override
  Future<Configuracion> guardar(Configuracion configuracion) async {
    final respuesta = await cliente.put(
      baseUri.resolve('/api/usuarios/${configuracion.idUsuario}/configuracion'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'sensibilidad': configuracion.sensibilidad,
        'velocidad_voz': configuracion.velocidadVoz,
        'modo_tonos': configuracion.modoTonos.valorBd,
        'volumen_maestro': configuracion.volumenMaestro,
      }),
    );
    final cuerpo = _decodificar(respuesta.body);
    if (respuesta.statusCode != 200) {
      throw StateError(
        cuerpo['detail'] as String? ?? 'Error guardando configuración.',
      );
    }
    return (await obtener(configuracion.idUsuario)) ?? configuracion;
  }
}

/// Adaptador HTTP para RF-DF. Conserva el contrato del repositorio que usa el
/// servicio de negocio y convierte las respuestas de Shelf al modelo local.
class RepositorioDestinosHttp implements RepositorioDestinos {
  RepositorioDestinosHttp(this.baseUri, this.cliente);

  final Uri baseUri;
  final http.Client cliente;

  @override
  Future<DestinoFrecuente> guardar(DestinoFrecuente destino) async {
    final respuesta = await cliente.post(
      baseUri.resolve('/api/usuarios/${destino.idUsuario}/destinos'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'etiqueta': destino.etiqueta,
        'latitud': destino.latitud,
        'longitud': destino.longitud,
        'direccion': destino.direccion,
      }),
    );
    final cuerpo = _decodificar(respuesta.body);
    if (respuesta.statusCode == 409) {
      throw EtiquetaDuplicadaError(destino.etiqueta);
    }
    if (respuesta.statusCode == 404) {
      throw const UsuarioInexistenteError();
    }
    if (respuesta.statusCode == 400) {
      throw RestriccionVioladaError(
        'ERR-15',
        cuerpo['detail'] as String? ?? 'Revisa la etiqueta y las coordenadas.',
      );
    }
    if (respuesta.statusCode != 201) {
      throw StateError(
        cuerpo['detail'] as String? ?? 'No se pudo guardar el destino.',
      );
    }
    return _desdeJson(cuerpo);
  }

  @override
  Future<DestinoFrecuente?> buscarPorId(int idDestino) async {
    final respuesta = await cliente.get(
      baseUri.resolve('/api/destinos/$idDestino'),
    );
    if (respuesta.statusCode == 404) return null;
    final cuerpo = _decodificar(respuesta.body);
    if (respuesta.statusCode != 200) {
      throw StateError(
        cuerpo['detail'] as String? ?? 'No se pudo consultar el destino.',
      );
    }
    return _desdeJson(cuerpo);
  }

  @override
  Future<List<DestinoFrecuente>> listarPorUsuario(int idUsuario) async {
    final respuesta = await cliente.get(
      baseUri.resolve('/api/usuarios/$idUsuario/destinos'),
    );
    if (respuesta.statusCode == 404) {
      throw const UsuarioInexistenteError();
    }
    if (respuesta.statusCode != 200) {
      final cuerpo = _decodificar(respuesta.body);
      throw StateError(
        cuerpo['detail'] as String? ?? 'No se pudieron consultar los destinos.',
      );
    }
    final valor = jsonDecode(respuesta.body);
    if (valor is! List) {
      throw const FormatException('La API devolvió una lista inválida.');
    }
    return valor
        .map((elemento) => _desdeJson(elemento as Map<String, dynamic>))
        .toList();
  }

  DestinoFrecuente _desdeJson(Map<String, dynamic> json) {
    final latitud = (json['latitud'] as num).toDouble();
    final longitud = (json['longitud'] as num).toDouble();
    return DestinoFrecuente(
      idDestino: (json['id_destino'] as num).toInt(),
      idUsuario: (json['id_usuario'] as num).toInt(),
      etiqueta: json['etiqueta'] as String,
      direccion: json['direccion'] as String? ?? 'Lat $latitud, Lon $longitud',
      latitud: latitud,
      longitud: longitud,
    );
  }
}

Map<String, dynamic> _decodificar(String cuerpo) {
  final valor = jsonDecode(cuerpo);
  if (valor is! Map<String, dynamic>) {
    throw const FormatException('La API devolvió una respuesta inválida.');
  }
  return valor;
}

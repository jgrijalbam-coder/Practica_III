import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../datos/modelos_datos.dart';
import '../datos/repositorio_configuracion.dart';
import '../datos/repositorio_usuarios.dart';
import 'autenticacion_service.dart';
import 'configuracion_service.dart';
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
      );

  final http.Client _cliente;

  @override
  final ServicioAutenticacion autenticacion;

  @override
  final ConfiguracionService configuracion;

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

Map<String, dynamic> _decodificar(String cuerpo) {
  final valor = jsonDecode(cuerpo);
  if (valor is! Map<String, dynamic>) {
    throw const FormatException('La API devolvió una respuesta inválida.');
  }
  return valor;
}

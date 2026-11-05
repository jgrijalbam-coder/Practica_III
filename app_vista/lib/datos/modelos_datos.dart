enum ModoTonos {
  frecuenciaSimple('frecuencia_simple'),
  espacializada('espacializada');

  const ModoTonos(this.valorBd);
  final String valorBd;

  static ModoTonos desdeBd(String valor) =>
      ModoTonos.values.firstWhere((m) => m.valorBd == valor);
}

class Usuario {
  final int idUsuario;
  final String nombre;
  final String correo;
  const Usuario({required this.idUsuario, required this.nombre, required this.correo});
}

class Configuracion {
  final int? idConfig;
  final int idUsuario;
  final double sensibilidad; // 0.4, 0.5 o 0.7
  final double velocidadVoz; // 0.8 a 2.0
  final ModoTonos modoTonos;
  final int volumenMaestro; // 50 a 95

  const Configuracion({
    this.idConfig,
    required this.idUsuario,
    this.sensibilidad = 0.5,
    this.velocidadVoz = 1.2,
    this.modoTonos = ModoTonos.frecuenciaSimple,
    this.volumenMaestro = 60,
  });
}

class DestinoFrecuente {
  final int? idDestino;
  final int idUsuario;
  final String etiqueta;
  final String direccion;
  final double latitud;
  final double longitud;

  const DestinoFrecuente({
    this.idDestino,
    required this.idUsuario,
    required this.etiqueta,
    required this.direccion,
    required this.latitud,
    required this.longitud,
  });
}

/// CONTRATO de datos (María José).
class Configuracion {
  double sensibilidadDeteccion; // 0.4 | 0.5 | 0.7
  double velocidadVoz; // 0.8 a 2.0
  int volumenMaestro; // 0 a 100

  Configuracion({
    this.sensibilidadDeteccion = 0.5,
    this.velocidadVoz = 1.2,
    this.volumenMaestro = 60,
  });
}

abstract class RepositorioConfiguracion {
  Future<Configuracion> leer();
  Future<void> guardar(Configuracion config);
}

/// Versión en memoria; se reemplaza por SQLite.
class RepositorioConfiguracionMemoria implements RepositorioConfiguracion {
  Configuracion _c = Configuracion();

  @override
  Future<Configuracion> leer() async => _c;

  @override
  Future<void> guardar(Configuracion config) async => _c = config;
}

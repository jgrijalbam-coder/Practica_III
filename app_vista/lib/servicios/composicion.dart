import '../datos/base_datos_mysql.dart';
import '../datos/repositorios_mysql.dart';
import 'autenticacion_service.dart';
import 'configuracion_service.dart';
import 'destinos_service.dart';

/// Servicios de la semana 14 ya cableados sobre una base abierta.
class ServiciosVista {
  const ServiciosVista({
    required this.autenticacion,
    required this.configuracion,
    required this.destinos,
    required this.usuarios,
  });

  final AutenticacionService autenticacion;
  final ConfiguracionService configuracion;
  final DestinosService destinos;
  final RepositorioUsuariosMySql usuarios;
}

/// Composicion de dependencias para la API: repositorios MySQL -> servicios.
ServiciosVista crearServicios(BaseDatosMySql baseDatos) {
  final usuarios = RepositorioUsuariosMySql(baseDatos);
  return ServiciosVista(
    autenticacion: AutenticacionService(
      repositorio: RepositorioAutenticacionMySql(baseDatos),
    ),
    configuracion: ConfiguracionService(
      usuarios: usuarios,
      configuracion: RepositorioConfiguracionMySql(baseDatos),
    ),
    destinos: DestinosService(
      usuarios: usuarios,
      destinos: RepositorioDestinosMySql(baseDatos),
    ),
    usuarios: usuarios,
  );
}

import '../datos/base_datos.dart';
import '../datos/repositorio_configuracion_sqlite.dart';
import '../datos/repositorio_destinos_sqlite.dart';
import '../datos/repositorio_usuarios_sqlite.dart';
import 'configuracion_service.dart';
import 'destinos_service.dart';

/// Servicios de la semana 14 ya cableados sobre una base abierta.
class ServiciosVista {
  const ServiciosVista({required this.configuracion, required this.destinos});

  final ConfiguracionService configuracion;
  final DestinosService destinos;
}

/// Composicion de dependencias: repositorio SQLite -> servicio.
///
/// Aqui se ve quien administra la transaccion y quien cierra la conexion:
/// la conexion la abre `BaseDatos.abrir` y la cierra quien la pidio con
/// `BaseDatos.cerrar()`; cada repositorio ejecuta una unica sentencia atomica
/// por operacion y SQLite la confirma o la revierte. Los servicios no abren
/// conexiones ni manejan transacciones.
ServiciosVista crearServicios(BaseDatos baseDatos) {
  final usuarios = RepositorioUsuariosSqlite(baseDatos);
  return ServiciosVista(
    configuracion: ConfiguracionService(
      usuarios: usuarios,
      configuracion: RepositorioConfiguracionSqlite(baseDatos),
    ),
    destinos: DestinosService(
      usuarios: usuarios,
      destinos: RepositorioDestinosSqlite(baseDatos),
    ),
  );
}

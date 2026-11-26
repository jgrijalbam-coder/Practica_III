import 'autenticacion_service.dart';
import 'configuracion_service.dart';
import 'destinos_service.dart';

abstract class ServiciosCuenta {
  ServicioAutenticacion get autenticacion;
  ConfiguracionService get configuracion;
  DestinosService get destinos;
  Future<void> cerrar();
}

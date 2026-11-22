import 'autenticacion_service.dart';
import 'configuracion_service.dart';

abstract class ServiciosCuenta {
  AutenticacionService get autenticacion;
  ConfiguracionService get configuracion;
  Future<void> cerrar();
}

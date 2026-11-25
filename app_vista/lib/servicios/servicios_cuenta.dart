import 'autenticacion_service.dart';
import 'configuracion_service.dart';

abstract class ServiciosCuenta {
  ServicioAutenticacion get autenticacion;
  ConfiguracionService get configuracion;
  Future<void> cerrar();
}

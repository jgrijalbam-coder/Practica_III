import 'cuenta_http.dart';
import 'servicios_cuenta.dart';

/// Android, Windows y macOS se conectan al backend HTTP; el backend administra
/// la conexión MySQL.
Future<ServiciosCuenta?> inicializarServiciosCuenta() async =>
    ServiciosCuentaHttp.crear();

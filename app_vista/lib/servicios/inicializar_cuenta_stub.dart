import 'cuenta_http.dart';
import 'servicios_cuenta.dart';

/// La versión web conserva su flujo actual de cámara sin SQLite móvil.
Future<ServiciosCuenta?> inicializarServiciosCuenta() async =>
    ServiciosCuentaHttp.crear();

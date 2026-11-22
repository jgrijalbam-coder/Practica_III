import 'inicializar_cuenta_stub.dart'
    if (dart.library.io) 'inicializar_cuenta_nativa.dart' as plataforma;
import 'servicios_cuenta.dart';

Future<ServiciosCuenta?> inicializarServiciosCuenta() =>
    plataforma.inicializarServiciosCuenta();

import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class FotogramaModelo {
  const FotogramaModelo({
    required this.bytesRgb,
    required this.ancho,
    required this.alto,
  });

  final Uint8List bytesRgb;
  final int ancho;
  final int alto;

  int get cantidadValores => bytesRgb.length;
}

class PreprocesadorFotograma {
  const PreprocesadorFotograma({this.tamano = 320});

  final int tamano;

  FotogramaModelo preparar(
    CameraImage fotograma, {
    required int sensorOrientation,
  }) {
    final imagen = _convertirRGB(fotograma);
    var preparada = img.copyResize(
      imagen,
      width: tamano,
      height: tamano,
    );

    if (sensorOrientation == 90) {
      preparada = img.copyRotate(preparada, angle: 90);
    } else if (sensorOrientation == 270) {
      preparada = img.copyRotate(preparada, angle: -90);
    } else if (sensorOrientation == 180) {
      preparada = img.copyRotate(preparada, angle: 180);
    }

    preparada = img.copyResize(
      preparada,
      width: tamano,
      height: tamano,
    );

    final bytes = Uint8List(tamano * tamano * 3);
    var indice = 0;
    for (final pixel in preparada) {
      bytes[indice++] = pixel.r.toInt();
      bytes[indice++] = pixel.g.toInt();
      bytes[indice++] = pixel.b.toInt();
    }

    return FotogramaModelo(
      bytesRgb: bytes,
      ancho: tamano,
      alto: tamano,
    );
  }

  img.Image _convertirRGB(CameraImage fotograma) {
    if (fotograma.planes.length == 1 &&
        fotograma.planes.first.bytes.length >=
            fotograma.width * fotograma.height * 4) {
      return img.Image.fromBytes(
        width: fotograma.width,
        height: fotograma.height,
        bytes: fotograma.planes.first.bytes,
        order: img.ChannelOrder.bgra,
      );
    }

    final y = fotograma.planes[0].bytes;
    final u = fotograma.planes.length > 1
        ? fotograma.planes[1].bytes
        : Uint8List(0);
    final v = fotograma.planes.length > 2
        ? fotograma.planes[2].bytes
        : u;

    final uvRowStride =
        fotograma.planes.length > 1 ? fotograma.planes[1].bytesPerRow : 0;
    final uvPixelStride =
        fotograma.planes.length > 1 ? fotograma.planes[1].bytesPerPixel ?? 1 : 1;
    final resultado = img.Image(
      width: fotograma.width,
      height: fotograma.height,
    );

    for (var yy = 0; yy < fotograma.height; yy++) {
      for (var xx = 0; xx < fotograma.width; xx++) {
        final indiceY = yy * fotograma.planes[0].bytesPerRow + xx;
        final indiceUv =
            (uvRowStride * (yy ~/ 2)) + (xx ~/ 2) * uvPixelStride;

        final yValor = indiceY < y.length ? y[indiceY] : 16;
        int uValor;
        int vValor;
        if (fotograma.planes.length >= 3) {
          uValor = indiceUv < u.length ? u[indiceUv] : 128;
          vValor = indiceUv < v.length ? v[indiceUv] : 128;
        } else {
          final parUv = indiceUv < u.length ? indiceUv : indiceUv - 1;
          uValor = parUv < u.length ? u[parUv & ~1] : 128;
          vValor =
              parUv + 1 < u.length ? u[(parUv & ~1) + 1] : 128;
        }

        final c = yValor - 16;
        final d = uValor - 128;
        final e = vValor - 128;
        final r = (298 * c + 409 * e + 128) >> 8;
        final g = (298 * c - 100 * d - 208 * e + 128) >> 8;
        final b = (298 * c + 516 * d + 128) >> 8;

        resultado.setPixelRgba(
          xx,
          yy,
          r.clamp(0, 255).toInt(),
          g.clamp(0, 255).toInt(),
          b.clamp(0, 255).toInt(),
          255,
        );
      }
    }

    return resultado;
  }
}

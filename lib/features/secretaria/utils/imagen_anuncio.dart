import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Tamaño máximo de la imagen ya codificada (data URL). Es el mismo límite de la API.
const kMaxImagenCaracteres = 300000;

/// Bytes de una data URL ("data:image/jpeg;base64,....") para mostrarla con Image.memory.
/// Si la data URL viene dañada (o es hostil) devuelve una lista vacía en vez de lanzar.
Uint8List bytesDeDataUrl(String dataUrl) {
  try {
    return base64Decode(dataUrl.substring(dataUrl.indexOf(',') + 1));
  } on FormatException {
    return Uint8List(0);
  }
}

/// Formato real según los primeros bytes (firma), sin fiarse del nombre del archivo.
String? _mimePorFirma(Uint8List b) {
  if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) return 'image/jpeg';
  if (b.length >= 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47 &&
      b[4] == 0x0D && b[5] == 0x0A && b[6] == 0x1A && b[7] == 0x0A) {
    return 'image/png';
  }
  if (b.length >= 12 && b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 &&
      b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) {
    return 'image/webp';
  }
  return null;
}

const _formatos = {'image/jpeg', 'image/png', 'image/webp'};

String? _mimePorNombre(String nombre) {
  final n = nombre.toLowerCase();
  if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return 'image/jpeg';
  if (n.endsWith('.png')) return 'image/png';
  if (n.endsWith('.webp')) return 'image/webp';
  return null;
}

/// RF-017 #3 / RF-022 #4: abre la galería y devuelve la imagen elegida como data URL.
/// La reduce a 900 px de lado y la comprime para que viaje liviana a la API.
/// Si la persona cancela, ambos valores vienen null; si la imagen no sirve, viene [error].
Future<({String? dataUrl, String? error})> elegirImagen() async {
  final XFile? archivo;
  try {
    archivo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      maxHeight: 900,
      imageQuality: 70,
    );
  } catch (_) {
    return (dataUrl: null, error: 'No se pudo abrir la galería.');
  }
  if (archivo == null) return (dataUrl: null, error: null);

  final mime = _formatos.contains(archivo.mimeType) ? archivo.mimeType : _mimePorNombre(archivo.name);
  if (mime == null) return (dataUrl: null, error: 'Formato no admitido. Use una imagen JPG, PNG o WebP.');

  // Tope de bytes antes de leer/codificar (base64 crece ~4/3) y firma real del archivo
  if (await archivo.length() > kMaxImagenCaracteres * 3 ~/ 4) {
    return (dataUrl: null, error: 'La imagen es demasiado pesada. Elija una más pequeña o en formato JPG.');
  }
  final bytes = await archivo.readAsBytes();
  final real = _mimePorFirma(bytes);
  if (real == null) {
    return (dataUrl: null, error: 'Formato no admitido. Use una imagen JPG, PNG o WebP.');
  }
  final dataUrl = 'data:$real;base64,${base64Encode(bytes)}';
  if (dataUrl.length > kMaxImagenCaracteres) {
    return (dataUrl: null, error: 'La imagen es demasiado pesada. Elija una más pequeña o en formato JPG.');
  }
  return (dataUrl: dataUrl, error: null);
}

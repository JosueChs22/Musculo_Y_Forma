import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Tamaño máximo de la imagen ya codificada (data URL). Es el mismo límite de la API.
const kMaxImagenCaracteres = 300000;

/// Bytes de una data URL ("data:image/jpeg;base64,....") para mostrarla con Image.memory.
Uint8List bytesDeDataUrl(String dataUrl) => base64Decode(dataUrl.substring(dataUrl.indexOf(',') + 1));

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

  final dataUrl = 'data:$mime;base64,${base64Encode(await archivo.readAsBytes())}';
  if (dataUrl.length > kMaxImagenCaracteres) {
    return (dataUrl: null, error: 'La imagen es demasiado pesada. Elija una más pequeña o en formato JPG.');
  }
  return (dataUrl: dataUrl, error: null);
}

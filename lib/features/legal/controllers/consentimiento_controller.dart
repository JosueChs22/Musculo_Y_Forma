import 'package:flutter/foundation.dart';

import '../../../core/api_exception.dart';
import '../../../core/base_controller.dart';
import '../../../core/datos_del_usuario.dart';
import '../legal_textos.dart';
import '../models/consentimiento.dart';
import '../services/legal_service.dart';

/// Consentimiento del usuario con sesión (Ley 8968) y sus derechos ARCO.
///
/// - [requiereAceptar]: el router muestra la pantalla de consentimiento (bloqueante).
/// - [datosSalud]: sin este consentimiento expreso no se piden ni se muestran mediciones.
///
/// Si la consulta falla (API caída o sin desplegar) no se bloquea la app, pero los datos de
/// salud quedan ocultos: ante la duda, se trata como "sin consentimiento".
class ConsentimientoController extends BaseController with DatosDelUsuario {
  ConsentimientoController(this._service);

  final LegalService _service;

  Consentimiento? _c;
  Consentimiento? get consentimiento => _c;

  bool _enviando = false;
  bool get enviando => _enviando;

  String? _errorAccion;
  String? get errorAccion => _errorAccion;

  bool get requiereAceptar =>
      idUsuario != null &&
      !loading &&
      error == null &&
      (_c?.requiereAceptar ?? false);

  bool get datosSalud => _c != null && !_c!.requiereAceptar && _c!.datosSalud;

  bool get supresionPendiente => _c?.solicitudSupresion?.pendiente ?? false;

  @override
  Future<void> cargarDatos() async {
    _c = await _service.obtenerConsentimiento();
  }

  @override
  void limpiar() {
    _c = null;
    _errorAccion = null;
    _enviando = false;
  }

  /// Acepta el aviso vigente. Devuelve true si la API lo registró.
  /// REGLA: no es optimista a propósito: la aceptación legal debe quedar confirmada en
  /// el servidor antes de dejar pasar al usuario.
  Future<bool> aceptar({required bool datosSalud}) async {
    if (_enviando) return false;
    _enviando = true;
    _errorAccion = null;
    notify();
    try {
      _c = await _service.guardarConsentimiento(
          version: kVersionLegal, datosSalud: datosSalud);
      return true;
    } on ApiException catch (e) {
      _errorAccion = e.mensaje;
      return false;
    } catch (e) {
      debugPrint('Error al guardar el consentimiento: $e');
      _errorAccion = 'No se pudo guardar tu respuesta. Inténtalo de nuevo.';
      return false;
    } finally {
      _enviando = false;
      notify();
    }
  }

  /// Da o retira el consentimiento de datos de salud (desde Perfil). Optimista: si la API
  /// falla se revierte y se avisa (REGLA 2).
  Future<bool> cambiarDatosSalud(bool valor) async {
    final previo = _c;
    if (previo == null || _enviando) return false;
    _enviando = true;
    _errorAccion = null;
    _c = previo.copyWith(datosSalud: valor);
    notify();
    try {
      _c = await _service.guardarConsentimiento(
          version: kVersionLegal, datosSalud: valor);
      return true;
    } catch (e) {
      _c = previo;
      _errorAccion = e is ApiException
          ? e.mensaje
          : 'No se pudo actualizar tu consentimiento.';
      return false;
    } finally {
      _enviando = false;
      notify();
    }
  }

  /// Copia de sus datos en JSON. Lanza [ApiException] si falla.
  Future<String> exportarDatos() => _service.exportarDatos();

  /// Registra la solicitud de eliminación. Devuelve el mensaje para el usuario.
  Future<String> solicitarSupresion({String? motivo}) async {
    final mensaje = await _service.solicitarSupresion(motivo: motivo);
    final c = _c;
    if (c != null) {
      _c = c.copyWith(
          solicitudSupresion:
              SolicitudSupresion(fecha: DateTime.now(), estado: 'Pendiente'));
      notify();
    }
    return mensaje;
  }
}

import 'package:flutter/foundation.dart';

import '../../../core/api_exception.dart';
import '../../../core/base_controller.dart';
import '../../auth/models/usuario.dart';
import '../services/usuarios_service.dart';

/// Lista de usuarios administrativos con búsqueda y filtro por rol, y alta de
/// nuevos usuarios. Se trae todo una vez y se filtra en memoria (son pocos).
class UsuariosController extends BaseController {
  UsuariosController(this._service);

  final UsuariosService _service;

  List<Usuario> _todos = const [];
  RolUsuario? _rol; // null = todos
  String _texto = '';

  bool _guardando = false;
  String? _errorCrear;

  RolUsuario? get rolFiltro => _rol;
  bool get guardando => _guardando;
  String? get errorCrear => _errorCrear;

  List<Usuario> get visibles {
    final q = _texto.trim().toLowerCase();
    return _todos.where((u) {
      if (_rol != null && u.rol != _rol) return false;
      if (q.isEmpty) return true;
      return u.nombreCompleto.toLowerCase().contains(q) ||
          u.usuario.toLowerCase().contains(q) ||
          u.correo.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Future<void> fetch() async {
    _todos = await _service.getUsuarios();
  }

  void filtrarRol(RolUsuario? rol) {
    _rol = rol;
    notify();
  }

  void buscar(String texto) {
    _texto = texto;
    notify();
  }

  /// Se llama al abrir el formulario para no mostrar el error de un intento anterior.
  void limpiarErrorCrear() => _errorCrear = null;

  /// RF-096. Devuelve true si se creó. Si falla, deja el mensaje en [errorCrear].
  Future<bool> crearUsuario({
    required String nombre,
    required String primerApellido,
    String? segundoApellido,
    required String correo,
    required String telefono,
    required RolUsuario rol,
    required String usuario,
    required String contrasena,
  }) async {
    if (_guardando) return false; // evita doble clic (REGLA 8)
    _guardando = true;
    _errorCrear = null;
    notify();
    try {
      final nuevo = await _service.crearUsuario(
        nombre: nombre,
        primerApellido: primerApellido,
        segundoApellido: segundoApellido,
        correo: correo,
        telefono: telefono,
        rol: rol,
        usuario: usuario,
        contrasena: contrasena,
      );
      _todos = [..._todos, nuevo]; // aparece en la lista sin volver a pedirla
      return true;
    } on ApiException catch (e) {
      _errorCrear = e.mensaje;
      return false;
    } catch (e) {
      debugPrint('Error inesperado al crear usuario: $e');
      _errorCrear = 'No se pudo crear el usuario. Inténtalo de nuevo.';
      return false;
    } finally {
      _guardando = false;
      notify();
    }
  }
}

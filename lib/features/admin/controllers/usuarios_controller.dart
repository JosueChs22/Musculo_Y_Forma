import 'package:flutter/foundation.dart';

import '../../../core/api_exception.dart';
import '../../../core/base_controller.dart';
import '../../auth/models/usuario.dart';
import '../services/usuarios_service.dart';

/// Usuarios administrativos: lista con búsqueda y filtros (RF-103, 104, 105),
/// alta (RF-096), edición (RF-099) e inhabilitación (RF-100).
/// Se trae todo una vez y se filtra en memoria (son pocos).
class UsuariosController extends BaseController {
  UsuariosController(this._service);

  final UsuariosService _service;

  List<Usuario> _todos = const [];
  RolUsuario? _rol; // null = todos
  EstadoUsuario? _estado; // null = todos
  String _texto = '';

  bool _guardando = false;
  String? _errorCrear;
  String? _errorEditar;
  String? _errorAccion;
  final Set<String> _inhabilitando = {};

  RolUsuario? get rolFiltro => _rol;
  EstadoUsuario? get estadoFiltro => _estado;
  bool get guardando => _guardando;
  String? get errorCrear => _errorCrear;
  String? get errorEditar => _errorEditar;
  String? get errorAccion => _errorAccion;

  /// ¿Hay una búsqueda o un filtro activo? (para el mensaje de "sin resultados")
  bool get hayFiltros => _rol != null || _estado != null || _texto.trim().isNotEmpty;

  bool estaInhabilitando(String id) => _inhabilitando.contains(id);

  /// RF-104 + RF-105: la búsqueda y los filtros se combinan (todos deben cumplirse).
  List<Usuario> get visibles {
    final q = _texto.trim().toLowerCase();
    return _todos.where((u) {
      if (_rol != null && u.rol != _rol) return false;
      if (_estado != null && u.estado != _estado) return false;
      if (q.isEmpty) return true;
      return u.id.toLowerCase().contains(q) || // identificador
          u.nombre.toLowerCase().contains(q) ||
          u.primerApellido.toLowerCase().contains(q) ||
          (u.segundoApellido ?? '').toLowerCase().contains(q) ||
          u.nombreCompleto.toLowerCase().contains(q) ||
          u.correo.toLowerCase().contains(q) ||
          u.usuario.toLowerCase().contains(q) ||
          u.rol.valor.toLowerCase().contains(q);
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

  void filtrarEstado(EstadoUsuario? estado) {
    _estado = estado;
    notify();
  }

  void buscar(String texto) {
    _texto = texto;
    notify();
  }

  /// Se llaman al abrir el formulario para no mostrar el error de un intento anterior.
  void limpiarErrorCrear() => _errorCrear = null;
  void limpiarErrorEditar() => _errorEditar = null;

  void _reemplazar(Usuario u) {
    _todos = [for (final x in _todos) x.id == u.id ? u : x];
  }

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

  /// RF-099. Devuelve true si se guardó. Si falla, deja el mensaje en [errorEditar].
  /// REGLA 2: aquí no es optimista porque el servidor valida (usuario o correo repetido).
  Future<bool> actualizarUsuario({
    required String id,
    required String nombre,
    required String primerApellido,
    String? segundoApellido,
    required String correo,
    required String telefono,
    required RolUsuario rol,
    required String usuario,
    String? contrasena,
  }) async {
    if (_guardando) return false; // evita doble clic (REGLA 8)
    _guardando = true;
    _errorEditar = null;
    notify();
    try {
      final actualizado = await _service.actualizarUsuario(
        id: id,
        nombre: nombre,
        primerApellido: primerApellido,
        segundoApellido: segundoApellido,
        correo: correo,
        telefono: telefono,
        rol: rol,
        usuario: usuario,
        contrasena: contrasena,
      );
      _reemplazar(actualizado);
      return true;
    } on ApiException catch (e) {
      _errorEditar = e.mensaje;
      return false;
    } catch (e) {
      debugPrint('Error inesperado al actualizar usuario: $e');
      _errorEditar = 'No se pudo guardar los cambios. Inténtalo de nuevo.';
      return false;
    } finally {
      _guardando = false;
      notify();
    }
  }

  /// RF-100. Actualización optimista (REGLA 2): el usuario pasa a Inhabilitado en
  /// la lista al instante y, si la API falla, se revierte y queda el mensaje en
  /// [errorAccion]. Devuelve true si el servidor lo confirmó.
  Future<bool> inhabilitarUsuario(String id) => _cambiarEstado(
        id,
        EstadoUsuario.inhabilitado,
        _service.inhabilitarUsuario,
        'No se pudo inhabilitar el usuario. Inténtalo de nuevo.',
      );

  /// Reactiva a un usuario inhabilitado. Misma mecánica que [inhabilitarUsuario].
  Future<bool> habilitarUsuario(String id) => _cambiarEstado(
        id,
        EstadoUsuario.activo,
        _service.habilitarUsuario,
        'No se pudo habilitar el usuario. Inténtalo de nuevo.',
      );

  Future<bool> _cambiarEstado(
    String id,
    EstadoUsuario nuevoEstado,
    Future<Usuario> Function(String id) llamar,
    String mensajeGenerico,
  ) async {
    if (_inhabilitando.contains(id)) return false; // evita doble clic (REGLA 8)
    final original = _todos.firstWhere((u) => u.id == id);
    _inhabilitando.add(id);
    _errorAccion = null;
    _reemplazar(original.copyWith(estado: nuevoEstado));
    notify();
    try {
      _reemplazar(await llamar(id));
      return true;
    } on ApiException catch (e) {
      _reemplazar(original);
      _errorAccion = e.mensaje;
      return false;
    } catch (e) {
      debugPrint('Error inesperado al cambiar el estado del usuario: $e');
      _reemplazar(original);
      _errorAccion = mensajeGenerico;
      return false;
    } finally {
      _inhabilitando.remove(id);
      notify();
    }
  }
}

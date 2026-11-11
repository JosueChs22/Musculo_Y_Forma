import '../../../core/base_controller.dart';
import '../../auth/models/usuario.dart';
import '../services/usuarios_service.dart';

/// Lista de usuarios administrativos con búsqueda y filtro por rol.
/// Se trae todo una vez y se filtra en memoria (son pocos registros).
class UsuariosController extends BaseController {
  UsuariosController(this._service);

  final UsuariosService _service;

  List<Usuario> _todos = const [];
  RolUsuario? _rol; // null = todos
  String _texto = '';

  RolUsuario? get rolFiltro => _rol;

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
}

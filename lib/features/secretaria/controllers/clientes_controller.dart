import 'package:flutter/foundation.dart';

import '../../../core/api_exception.dart';
import '../../../core/debouncer.dart';
import '../models/cliente.dart';
import '../services/clientes_service.dart';

class ClientesController extends ChangeNotifier {
  ClientesController(this._service);

  static const _retrasoBusqueda = Duration(milliseconds: 300);

  final ClientesService _service;
  final Debouncer _buscador = Debouncer(delay: _retrasoBusqueda);

  bool _guardando = false;
  bool _actualizando = false;
  bool _cargandoLista = false;
  bool _cargandoMas = false;
  bool _listaCargada = false;
  String? _errorCrear;
  String? _errorLista;
  String? _errorAccion;
  String? _estadoFiltro;
  String _busqueda = '';
  String? _nextCursor;
  List<Cliente> _clientes = const [];
  int _versionCarga = 0;

  bool get guardando => _guardando;
  bool get actualizando => _actualizando;
  bool get cargandoLista => _cargandoLista;
  bool get cargandoMas => _cargandoMas;
  bool get listaCargada => _listaCargada;
  bool get hayMas => _nextCursor != null;
  String? get errorCrear => _errorCrear;
  String? get errorLista => _errorLista;
  String? get errorAccion => _errorAccion;
  String? get estadoFiltro => _estadoFiltro;
  String get busqueda => _busqueda;
  List<Cliente> get clientes => _clientes;

  void limpiarErrorCrear() {
    if (_errorCrear == null) return;
    _errorCrear = null;
    notifyListeners();
  }

  void limpiarErrorAccion() {
    if (_errorAccion == null) return;
    _errorAccion = null;
    notifyListeners();
  }

  Future<bool> crearCliente({
    required String nombre,
    required String primerApellido,
    required String segundoApellido,
    required String correo,
    required String cedula,
    required String telefono,
    required String carne,
    required DateTime fechaIngreso,
  }) async {
    if (_guardando) return false;
    _guardando = true;
    _errorCrear = null;
    notifyListeners();
    try {
      await _service.crearCliente(
        nombre: nombre,
        primerApellido: primerApellido,
        segundoApellido: segundoApellido,
        correo: correo,
        cedula: cedula,
        telefono: telefono,
        carne: carne,
        fechaIngreso: fechaIngreso,
      );
      return true;
    } on ApiException catch (e) {
      _errorCrear = e.mensaje;
      return false;
    } catch (e) {
      debugPrint('Error inesperado al crear cliente: $e');
      _errorCrear = 'No se pudo registrar el cliente. Inténtalo de nuevo.';
      return false;
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }

  Future<void> cargarClientes({bool reiniciar = false}) async {
    if (!reiniciar && (_cargandoLista || _cargandoMas)) return;
    if (!reiniciar && !_listaCargada) reiniciar = true;
    if (!reiniciar && _nextCursor == null) return;

    final cursor = reiniciar ? null : _nextCursor;
    final version = reiniciar ? ++_versionCarga : _versionCarga;
    _cargandoLista = reiniciar;
    _cargandoMas = !reiniciar;
    _errorLista = null;
    notifyListeners();
    try {
      final pagina = await _service.listarClientes(
        estado: _estadoFiltro,
        busqueda: _busqueda.isEmpty ? null : _busqueda,
        cursor: cursor,
      );
      if (version != _versionCarga) return;
      _clientes = reiniciar ? pagina.items : [..._clientes, ...pagina.items];
      _nextCursor = pagina.nextCursor;
      _listaCargada = true;
    } on ApiException catch (e) {
      if (version != _versionCarga) return;
      _errorLista = e.mensaje;
    } catch (e) {
      if (version != _versionCarga) return;
      debugPrint('Error inesperado al cargar clientes: $e');
      _errorLista = 'No se pudo cargar la lista de clientes.';
    } finally {
      if (version == _versionCarga) {
        _cargandoLista = false;
        _cargandoMas = false;
        notifyListeners();
      }
    }
  }

  Future<void> filtrarEstado(String? estado) async {
    if (_estadoFiltro == estado) return;
    _estadoFiltro = estado;
    _listaCargada = false;
    await cargarClientes(reiniciar: true);
  }

  void buscar(String texto) {
    final nuevaBusqueda = texto.trim();
    if (_busqueda == nuevaBusqueda) return;
    _busqueda = nuevaBusqueda;
    _buscador.run(() => cargarClientes(reiniciar: true));
    notifyListeners();
  }

  Future<bool> actualizarCliente({
    required Cliente original,
    required String nombre,
    required String primerApellido,
    required String segundoApellido,
    required String correo,
    required String cedula,
    required String telefono,
    required String carne,
    required DateTime fechaIngreso,
  }) async {
    if (_actualizando) return false;
    _actualizando = true;
    _errorAccion = null;
    final clientesAnteriores = _clientes;
    final actualizado = original.copyWith(
      nombre: nombre.trim(),
      primerApellido: primerApellido.trim(),
      segundoApellido: segundoApellido.trim(),
      correo: correo.trim(),
      cedula: cedula.trim(),
      telefono: telefono.trim(),
      carne: carne.trim(),
      fechaIngreso: fechaIngreso,
    );
    _reemplazarCliente(actualizado);
    notifyListeners();
    try {
      final confirmado = await _service.actualizarCliente(
        original.id,
        nombre: nombre,
        primerApellido: primerApellido,
        segundoApellido: segundoApellido,
        correo: correo,
        cedula: cedula,
        telefono: telefono,
        carne: carne,
        fechaIngreso: fechaIngreso,
      );
      _reemplazarCliente(confirmado);
      return true;
    } on ApiException catch (e) {
      _clientes = clientesAnteriores;
      _errorAccion = e.mensaje;
      return false;
    } catch (e) {
      debugPrint('Error inesperado al actualizar cliente: $e');
      _clientes = clientesAnteriores;
      _errorAccion = 'No se pudo actualizar el cliente. Inténtalo de nuevo.';
      return false;
    } finally {
      _actualizando = false;
      notifyListeners();
    }
  }

  Future<bool> cambiarEstadoCliente(
    Cliente original,
    EstadoCliente estado,
  ) async {
    if (_actualizando) return false;
    _actualizando = true;
    _errorAccion = null;
    final clientesAnteriores = _clientes;
    _reemplazarCliente(original.copyWith(estado: estado));
    notifyListeners();
    try {
      final confirmado =
          await _service.cambiarEstadoCliente(original.id, estado);
      _reemplazarCliente(confirmado);
      return true;
    } on ApiException catch (e) {
      _clientes = clientesAnteriores;
      _errorAccion = e.mensaje;
      return false;
    } catch (e) {
      debugPrint('Error inesperado al cambiar el estado del cliente: $e');
      _clientes = clientesAnteriores;
      _errorAccion = 'No se pudo cambiar el estado del cliente.';
      return false;
    } finally {
      _actualizando = false;
      notifyListeners();
    }
  }

  void _reemplazarCliente(Cliente cliente) {
    final indice =
        _clientes.indexWhere((existente) => existente.id == cliente.id);
    if (indice < 0) return;
    final coincideFiltro =
        _estadoFiltro == null || _estadoFiltro == cliente.estado.valor;
    if (!coincideFiltro) {
      _clientes = [
        for (final existente in _clientes)
          if (existente.id != cliente.id) existente,
      ];
      return;
    }
    _clientes = [
      for (var i = 0; i < _clientes.length; i++)
        if (i == indice) cliente else _clientes[i],
    ];
  }

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }
}

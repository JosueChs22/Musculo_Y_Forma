/// Validadores de formularios.
/// Cada función devuelve un mensaje de error, o null si el valor es válido.
/// Ese es el formato que espera el parámetro `validator` de TextFormField.
class Validators {
  Validators._(); // evita crear instancias: solo se usan sus funciones estáticas

  static String? requerido(String? v, [String campo = 'Este campo']) {
    if (v == null || v.trim().isEmpty) return '$campo es obligatorio';
    return null;
  }

  static String? correo(String? v) {
    final vacio = requerido(v, 'El correo');
    if (vacio != null) return vacio;
    final valido = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v!.trim());
    return valido ? null : 'Ingrese un correo válido';
  }

  /// Política acordada: mínimo 8 caracteres, al menos una letra y un número,
  /// sin espacios.
  static String? contrasena(String? v) {
    if (v == null || v.isEmpty) return 'La contraseña es obligatoria';
    if (v.length < 8) return 'Debe tener al menos 8 caracteres';
    if (v.contains(RegExp(r'\s'))) return 'No puede contener espacios';
    if (!v.contains(RegExp(r'[A-Za-z]'))) return 'Debe incluir al menos una letra';
    if (!v.contains(RegExp(r'\d'))) return 'Debe incluir al menos un número';
    return null;
  }

  /// La confirmación debe ser igual a la contraseña escrita arriba.
  static String? confirmacion(String? v, String contrasena) {
    if (v == null || v.isEmpty) return 'Confirme la contraseña';
    return v == contrasena ? null : 'Las contraseñas no coinciden';
  }

  /// RF-035 #9: la nueva contraseña no puede ser igual a la actual.
  static String? distintaDeActual(String? nueva, String actual) {
    return nueva == actual
        ? 'La nueva contraseña debe ser distinta a la actual'
        : null;
  }

  /// Teléfono de Costa Rica: 8 dígitos.
  static String? telefono(String? v) {
    final vacio = requerido(v, 'El teléfono');
    if (vacio != null) return vacio;
    return RegExp(r'^\d{8}$').hasMatch(v!.trim()) ? null : 'Debe tener 8 dígitos';
  }
}

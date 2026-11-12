import 'package:flutter/material.dart';

import '../features/auth/models/usuario.dart';

/// Panel de trabajo de un rol. Inicio, Rutinas, Progreso y Perfil los ve todo
/// usuario con sesión; los paneles, solo los roles indicados.
class PanelRol {
  const PanelRol(this.titulo, this.ruta, this.icono, this.roles);

  final String titulo;
  final String ruta;
  final IconData icono;
  final Set<RolUsuario> roles;

  /// La ruta del panel y todas sus subrutas (/coach, /coach/plan/…).
  bool cubre(String ruta) => ruta == this.ruta || ruta.startsWith('${this.ruta}/');
}

/// Única fuente de permisos de pantalla: la usan el router, el menú y Perfil.
/// Es protección de interfaz; la seguridad real la valida la API con el token.
const paneles = [
  PanelRol('Panel de coach', '/coach', Icons.sports_gymnastics, {RolUsuario.entrenador, RolUsuario.administrador}),
  PanelRol('Panel de secretaria', '/secretaria', Icons.event_note_outlined,
      {RolUsuario.secretaria, RolUsuario.administrador}),
  PanelRol('Administración', '/admin', Icons.admin_panel_settings_outlined, {RolUsuario.administrador}),
];

/// Paneles que ve [rol], en el orden del menú.
List<PanelRol> panelesDe(RolUsuario? rol) => [for (final p in paneles) if (rol != null && p.roles.contains(rol)) p];

/// ¿Puede [rol] abrir [ruta]? Las rutas que no son de un panel son de todos.
bool puedeEntrar(RolUsuario? rol, String ruta) {
  for (final p in paneles) {
    if (p.cubre(ruta)) return rol != null && p.roles.contains(rol);
  }
  return true;
}

/// Panel al que pertenece [ruta], o null si es una pantalla común.
PanelRol? panelDe(String ruta) {
  for (final p in paneles) {
    if (p.cubre(ruta)) return p;
  }
  return null;
}

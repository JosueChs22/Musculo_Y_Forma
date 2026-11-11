import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/brand.dart';
import '../../../core/theme.dart';
import '../../../core/validators.dart';
import '../../../core/widgets.dart';
import '../controllers/auth_controller.dart';

/// Recuperación de contraseña (RF-034) en dos pasos dentro de la misma pantalla:
/// 1) pedir el código con el correo, 2) ingresar el código y la contraseña nueva.
class RecuperarView extends StatefulWidget {
  const RecuperarView({super.key});

  @override
  State<RecuperarView> createState() => _RecuperarViewState();
}

class _RecuperarViewState extends State<RecuperarView> {
  final _formCorreo = GlobalKey<FormState>();
  final _formCodigo = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _codigo = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();

  int _paso = 1;
  bool _ocultar = true;
  String? _aviso; // mensaje informativo (por ejemplo, "código reenviado")

  @override
  void initState() {
    super.initState();
    context.read<AuthController>().limpiarErrorRecuperacion();
  }

  @override
  void dispose() {
    for (final c in [_correo, _codigo, _nueva, _confirmar]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pedirCodigo({bool reenvio = false}) async {
    if (!_formCorreo.currentState!.validate()) return;
    final ok = await context.read<AuthController>().solicitarRecuperacion(_correo.text);
    if (!ok || !mounted) return;
    setState(() {
      _paso = 2;
      _aviso = reenvio ? 'Te enviamos un código nuevo.' : null;
    });
  }

  Future<void> _reenviar() async {
    final ok = await context.read<AuthController>().solicitarRecuperacion(_correo.text);
    if (!ok || !mounted) return;
    setState(() => _aviso = 'Te enviamos un código nuevo.');
  }

  Future<void> _restablecer() async {
    if (!_formCodigo.currentState!.validate()) return;
    final ok = await context.read<AuthController>().restablecerContrasena(
          correo: _correo.text,
          codigo: _codigo.text,
          nueva: _nueva.text,
        );
    if (!ok || !mounted) return;
    // El mensaje sobrevive al cambio de pantalla porque el ScaffoldMessenger vive en MaterialApp
    final messenger = ScaffoldMessenger.of(context);
    context.go('/login');
    messenger.showSnackBar(
      const SnackBar(content: Text('Contraseña restablecida. Ya puedes iniciar sesión.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final ocupado = auth.recuperando;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandLockup(),
                  const SizedBox(height: 32),
                  Text('RECUPERAR CONTRASEÑA', style: display(30)),
                  const SizedBox(height: 4),
                  Text(
                    _paso == 1
                        ? 'Ingresa el correo de tu cuenta y te enviaremos un código.'
                        : 'Si el correo está registrado, te enviamos un código de 6 dígitos. '
                            'Vence en 15 minutos.',
                    style: ts(15, color: AppColors.pizarra),
                  ),
                  const SizedBox(height: 24),
                  if (_paso == 1) _paso1(ocupado) else _paso2(ocupado),
                  if (auth.errorRecuperacion != null) ...[
                    const SizedBox(height: 16),
                    Text(auth.errorRecuperacion!, style: ts(14, weight: kSemi, color: AppColors.danger)),
                  ] else if (_aviso != null) ...[
                    const SizedBox(height: 16),
                    Text(_aviso!, style: ts(14, weight: kSemi, color: AppColors.success)),
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: ocupado ? null : () => context.go('/login'),
                    child: Text('Volver a iniciar sesión',
                        style: ts(15, weight: kSemi, color: AppColors.cobalto)),
                  ),
                  if (ocupado) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Conectando… la primera vez puede tardar hasta un minuto.',
                      textAlign: TextAlign.center,
                      style: ts(13, color: AppColors.pizarra),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paso1(bool ocupado) => Form(
        key: _formCorreo,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextFormField(
            controller: _correo,
            enabled: !ocupado,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) => _pedirCodigo(),
            decoration: const InputDecoration(labelText: 'Correo electrónico'),
            validator: Validators.correo,
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Enviar código', expand: true, busy: ocupado, onPressed: _pedirCodigo),
        ]),
      );

  Widget _paso2(bool ocupado) => Form(
        key: _formCodigo,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Código enviado a ${_correo.text.trim()}', style: ts(14, weight: kSemi)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _codigo,
            enabled: !ocupado,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            decoration: const InputDecoration(labelText: 'Código de 6 dígitos'),
            validator: (v) => RegExp(r'^\d{6}$').hasMatch((v ?? '').trim()) ? null : 'Ingresa los 6 dígitos',
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _nueva,
            enabled: !ocupado,
            obscureText: _ocultar,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'Nueva contraseña',
              suffixIcon: IconButton(
                tooltip: _ocultar ? 'Mostrar contraseñas' : 'Ocultar contraseñas',
                icon: Icon(_ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _ocultar = !_ocultar),
              ),
            ),
            validator: Validators.contrasena,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirmar,
            enabled: !ocupado,
            obscureText: _ocultar,
            autofillHints: const [AutofillHints.newPassword],
            onFieldSubmitted: (_) => _restablecer(),
            decoration: const InputDecoration(labelText: 'Confirmar nueva contraseña'),
            validator: (v) => Validators.confirmacion(v, _nueva.text),
          ),
          const SizedBox(height: 6),
          Text(
            'Mínimo 8 caracteres, con al menos una letra y un número, sin espacios.',
            style: ts(13, color: AppColors.pizarra),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Restablecer contraseña',
            expand: true,
            busy: ocupado,
            onPressed: _restablecer,
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TextButton(
              onPressed: ocupado ? null : _reenviar,
              child: Text('Reenviar código', style: ts(14, weight: kSemi, color: AppColors.cobalto)),
            ),
            TextButton(
              onPressed: ocupado ? null : () => setState(() => _paso = 1),
              child: Text('Cambiar correo', style: ts(14, weight: kSemi, color: AppColors.cobalto)),
            ),
          ]),
        ]),
      );
}

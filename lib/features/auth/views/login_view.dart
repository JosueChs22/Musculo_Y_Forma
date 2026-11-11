import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/brand.dart';
import '../../../core/theme.dart';
import '../../../core/validators.dart';
import '../controllers/auth_controller.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _form = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _contrasena = TextEditingController();
  bool _ocultar = true;

  @override
  void dispose() {
    _usuario.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    // Si el login funciona, el router (app.dart) redirige solo al inicio.
    await context.read<AuthController>().iniciarSesion(_usuario.text, _contrasena.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BrandLockup(),
                    const SizedBox(height: 32),
                    Text('INICIAR SESIÓN', style: display(30)),
                    const SizedBox(height: 4),
                    Text('Ingresa con tu usuario y contraseña.',
                        style: ts(15, color: AppColors.pizarra)),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usuario,
                      enabled: !auth.enviando,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(labelText: 'Usuario'),
                      validator: (v) => Validators.requerido(v, 'El usuario'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contrasena,
                      enabled: !auth.enviando,
                      obscureText: _ocultar,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _enviar(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        suffixIcon: IconButton(
                          tooltip: _ocultar ? 'Mostrar contraseña' : 'Ocultar contraseña',
                          icon: Icon(_ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _ocultar = !_ocultar),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'La contraseña es obligatoria' : null,
                    ),
                    if (auth.errorLogin != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        auth.errorLogin!,
                        style: ts(14, weight: kSemi, color: AppColors.danger),
                      ),
                    ],
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: auth.enviando ? null : () => context.go('/recuperar'),
                        child: Text('¿Olvidó su contraseña?',
                            style: ts(14, weight: kSemi, color: AppColors.cobalto)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: auth.enviando ? null : _enviar,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.ambar,
                        foregroundColor: AppColors.ink,
                        disabledBackgroundColor: AppColors.ambar.withValues(alpha: .6),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: auth.enviando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.ink),
                            )
                          : Text('INGRESAR', style: ts(16, weight: kSemi)),
                    ),
                    if (auth.enviando) ...[
                      const SizedBox(height: 12),
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
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../legal_textos.dart';
import 'widgets/aviso_borrador.dart';

/// Aviso de privacidad (/privacidad) o Términos y condiciones (/terminos).
/// Públicas: se abren con o sin sesión. Solo lectura y responsivas.
class DocumentoLegalView extends StatelessWidget {
  const DocumentoLegalView({super.key, required this.documento});

  final DocumentoLegal documento;

  void _volver(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/'); // sin sesión, el router lo manda al login
    }
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final h = ancho >= 800 ? 48.0 : 16.0;
    final secciones = documento.secciones;
    return Scaffold(
      backgroundColor: AppColors.niebla,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: CustomScrollView(slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(h, 16, h, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          TextButton.icon(
                            onPressed: () => _volver(context),
                            style: TextButton.styleFrom(
                                minimumSize: const Size(44, 44),
                                foregroundColor: AppColors.cobalto),
                            icon: const Icon(Icons.arrow_back, size: 18),
                            label: Text('Volver',
                                style: ts(14,
                                    weight: kSemi, color: AppColors.cobalto)),
                          ),
                          const Expanded(
                            child: Align(
                                alignment: Alignment.centerRight,
                                child: BrandLockup(compacto: true)),
                          ),
                        ]),
                        const SizedBox(height: 20),
                        Semantics(
                          header: true,
                          child: PageTitle(
                              eyebrow: 'Músculo y Forma',
                              title: documento.titulo),
                        ),
                        const SizedBox(height: 12),
                        Text('Versión $kVersionLegal · $kFechaLegal',
                            style: ts(14,
                                weight: kSemi, color: AppColors.pizarra)),
                        const SizedBox(height: 16),
                        const AvisoBorrador(),
                        const SizedBox(height: 16),
                        Text(documento.resumen,
                            style: ts(16, color: AppColors.ink, height: 1.45)),
                        const SizedBox(height: 24),
                      ]),
                ),
              ),
              // REGLA 4: secciones con builder
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: h),
                sliver: SliverList.builder(
                  itemCount: secciones.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _Seccion(secciones[i]),
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion(this.s);
  final SeccionLegal s;

  @override
  Widget build(BuildContext context) => Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(
              header: true,
              child: Text(s.titulo,
                  style: ts(18, weight: kSemi, color: AppColors.indigo))),
          const SizedBox(height: 10),
          for (final p in s.parrafos)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SelectableText(p, style: ts(15, height: 1.5)),
            ),
        ]),
      );
}

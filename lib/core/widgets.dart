import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Tarjeta blanca con borde suave.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = AppColors.card,
    this.radius = 18,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
  }
}

/// Tarjeta seleccionable: índigo cuando está activa.
class SelectableCard extends StatelessWidget {
  const SelectableCard({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.semanticLabel,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: padding,
            decoration: BoxDecoration(
              color: selected ? AppColors.indigo : AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: selected ? AppColors.indigo : AppColors.line),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Etiqueta pequeña en mayúsculas sobre los títulos.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = AppColors.pizarra});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: ts(12, weight: kSemi, color: color, spacing: 2));
}

class InfoChip extends StatelessWidget {
  const InfoChip(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: AppColors.niebla, borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: ts(13, weight: kSemi, color: AppColors.pizarra)),
      );
}

/// Píldora de estado. [tone]: ámbar (logros) o cobalto (información).
enum PillTone { ambar, cobalto }

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.tone = PillTone.ambar});
  final String text;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final ambar = tone == PillTone.ambar;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: ambar ? AppColors.ambar : AppColors.cobalto,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(text, style: ts(13, weight: kSemi, color: ambar ? AppColors.ink : Colors.white)),
    );
  }
}

class MiniBar extends StatelessWidget {
  const MiniBar({
    super.key,
    required this.value,
    this.track = AppColors.track,
    this.fill = AppColors.cobalto,
    this.height = 8,
  });
  final double value;
  final Color track;
  final Color fill;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Container(
        height: height,
        color: track,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(color: fill),
        ),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar(
    this.initials, {
    super.key,
    this.size = 48,
    this.bg = AppColors.cobalto,
    this.fg = Colors.white,
  });
  final String initials;
  final double size;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Text(initials, style: ts(size * .32, weight: kSemi, color: fg)),
      );
}

/// Botón principal (ámbar con texto tinta).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  /// Muestra un indicador dentro del botón y lo deshabilita (REGLAS 1 y 8).
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.ink),
          )
        : Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis, style: ts(16, weight: kSemi, color: AppColors.ink)),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, size: 20, color: AppColors.ink),
            ],
          ]);
    final button = FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ambar,
        disabledBackgroundColor: const Color(0x99FFB547),
        foregroundColor: AppColors.ink,
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: child,
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Botón secundario (contorno cobalto).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.cobalto,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: const BorderSide(color: AppColors.cobalto, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis, style: ts(15, weight: kSemi, color: AppColors.cobalto)),
          ),
          if (icon != null) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 18, color: AppColors.cobalto),
          ],
        ]),
      );
}

class BackLink extends StatelessWidget {
  const BackLink({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(44, 44),
          foregroundColor: AppColors.cobalto,
        ),
        icon: const Icon(Icons.arrow_back, size: 18),
        label: Text('Volver al inicio', style: ts(14, weight: kSemi, color: AppColors.cobalto)),
      );
}

/// Título de página: etiqueta + título en Barlow Condensed.
class PageTitle extends StatelessWidget {
  const PageTitle({super.key, this.eyebrow, required this.title, this.subtitle});
  final String? eyebrow;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final big = MediaQuery.sizeOf(context).width >= 640;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (eyebrow != null) ...[Eyebrow(eyebrow!), const SizedBox(height: 6)],
      Text(title.toUpperCase(), style: display(big ? 48 : 38)),
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        Text(subtitle!, style: ts(15, color: AppColors.pizarra)),
      ],
    ]);
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.eyebrow, required this.title, this.trailing});
  final String eyebrow;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(eyebrow),
                const SizedBox(height: 6),
                Text(title.toUpperCase(), style: display(30)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      );
}

/// Página con scroll basada en slivers (REGLA 4): los bloques fijos van como
/// [SliverToBoxAdapter] y las listas largas como [SliverList.builder].
class SliverPage extends StatelessWidget {
  const SliverPage({super.key, required this.slivers});
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;
    final h = wide ? 48.0 : 20.0;
    return CustomScrollView(slivers: [
      SliverPadding(padding: EdgeInsets.fromLTRB(h, wide ? 36 : 24, h, 0)),
      for (final s in slivers) SliverPadding(padding: EdgeInsets.symmetric(horizontal: h), sliver: s),
      SliverPadding(padding: EdgeInsets.only(bottom: wide ? 48 : 120)),
    ]);
  }
}

/// Atajo para poner un widget normal dentro de [SliverPage].
class Box extends StatelessWidget {
  const Box(this.child, {super.key, this.gapAfter = 0});
  final Widget child;
  final double gapAfter;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
        child: Padding(padding: EdgeInsets.only(bottom: gapAfter), child: child),
      );
}

/// Dos columnas en pantallas anchas, apiladas en pantallas angostas.
class TwoCol extends StatelessWidget {
  const TwoCol({
    super.key,
    required this.left,
    required this.right,
    this.leftWidth,
    this.leftFlex = 1,
    this.rightFlex = 1,
    this.gap = 24,
    this.breakpoint = 820,
  });
  final Widget left;
  final Widget right;
  final double? leftWidth;
  final int leftFlex;
  final int rightFlex;
  final double gap;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      if (box.maxWidth < breakpoint) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [left, SizedBox(height: gap), right],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftWidth != null
              ? SizedBox(width: leftWidth, child: left)
              : Expanded(flex: leftFlex, child: left),
          SizedBox(width: gap),
          Expanded(flex: rightFlex, child: right),
        ],
      );
    });
  }
}

/// Grilla responsiva para conjuntos ACOTADOS (métricas, días de la semana).
/// Para listas que pueden crecer usar SliverList / ListView.builder (REGLA 4).
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({super.key, required this.children, this.desktopCols = 3, this.spacing = 16});
  final List<Widget> children;
  final int desktopCols;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final width = box.maxWidth;
      final cols = width >= 760
          ? desktopCols
          : width >= 520
              ? math.min(2, desktopCols)
              : 1;
      final itemW = (width - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [for (final c in children) SizedBox(width: itemW, child: c)],
      );
    });
  }
}

/// Mensaje de error con opción de reintentar.
class ErrorPanel extends StatelessWidget {
  const ErrorPanel({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Panel(
        child: Row(children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: ts(14, color: AppColors.ink))),
          const SizedBox(width: 12),
          SecondaryButton(label: 'Reintentar', onPressed: onRetry),
        ]),
      );
}

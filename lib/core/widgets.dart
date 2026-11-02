import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.radius = 16,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? w(.035),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: w(.08)),
      ),
      child: child,
    );
  }
}

class SelectableCard extends StatelessWidget {
  const SelectableCard({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : w(.035),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.accent : w(.08)),
        ),
        child: child,
      ),
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = AppColors.accentLight});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: ts(11.5, weight: kXBold, color: color, spacing: 1.8));
}

class InfoChip extends StatelessWidget {
  const InfoChip(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: w(.05), borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: ts(12, weight: kSemi, color: w(.55))),
      );
}

class AccentPill extends StatelessWidget {
  const AccentPill(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 90, 54, .15),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(text, style: ts(12, weight: kXBold, color: AppColors.accentLight)),
      );
}

class MiniBar extends StatelessWidget {
  const MiniBar({super.key, required this.value, required this.track, this.fill, this.gradient});
  final double value;
  final Color track;
  final Color? fill;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Container(
        height: 6,
        color: track,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(decoration: BoxDecoration(color: fill, gradient: gradient)),
        ),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar(this.initials, {super.key, this.size = 48, this.bg = AppColors.accent, this.fg = Colors.white});
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
        child: Text(initials, style: ts(size * .28, weight: kBlack, color: fg)),
      );
}

class WhiteButton extends StatelessWidget {
  const WhiteButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
  });
  final String label;
  final VoidCallback onPressed;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: padding,
            child: Text(label, textAlign: TextAlign.center, style: ts(14, weight: kBlack, color: Colors.black)),
          ),
        ),
      );
}

class BackLink extends StatelessWidget {
  const BackLink({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Text('← Volver al inicio', style: ts(14, weight: kSemi, color: w(.4))),
      );
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
                const SizedBox(height: 8),
                Text(title, style: ts(24, weight: kBlack, spacing: -.4)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      );
}

/// Contenedor de página con scroll y padding responsivo.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;
    final h = wide ? 48.0 : 20.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(h, wide ? 36 : 24, h, wide ? 48 : 110),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
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

/// Grilla responsiva: 1 columna en móvil, 2 en tablet, [desktopCols] en escritorio.
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

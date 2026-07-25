import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:lookup_user/src/theme.dart';

/// Marca LookUp: el PNG del logo tal cual, sin fondos ni contenedores.
/// La variante mini queda reservada para espacios cuadrados realmente compactos.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 28, this.mini = false});

  final double size;
  final bool mini;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      mini
          ? 'assets/images/logoLookUpMini.png'
          : 'assets/images/logo_lookup.png',
      height: size,
      fit: BoxFit.contain,
    );
  }
}

/// Superficie de marca para momentos clave (acceso, cabeceras y vacantes).
/// El degradado y los anillos son planos: no usan glow ni sombras.
class BrandGradientPanel extends StatelessWidget {
  const BrandGradientPanel({
    super.key,
    required this.child,
    this.height,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.showTopRightRing = true,
    this.showBottomLeftRing = true,
  });

  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final bool showTopRightRing;
  final bool showBottomLeftRing;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(gradient: kLookUpBrandGradient),
            ),
            if (showTopRightRing)
              const Positioned(
                right: -82,
                top: -104,
                child: _BrandRing(size: 286, stroke: 34),
              ),
            if (showBottomLeftRing)
              const Positioned(
                left: -92,
                bottom: -142,
                child: _BrandRing(size: 260, stroke: 30),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

class _BrandRing extends StatelessWidget {
  const _BrandRing({required this.size, required this.stroke});

  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: stroke,
          ),
        ),
      ),
    );
  }
}

/// Avatar con iniciales de un nombre (empresas o vacantes sin logo).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.color,
  });

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.take(2).map((p) => p[0].toUpperCase()).join();
    final base = color ?? context.colors.brand;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: base.withValues(alpha: context.colors.chipAlpha + 0.04),
        borderRadius: BorderRadius.circular(size * 0.26),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: base,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}

/// Fila etiqueta/valor del perfil, separada por una línea.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final valueText = Text(
      value.trim(),
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: c.ink,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) => Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            Icon(icon, color: c.inkFaint, size: 19),
            const SizedBox(width: 12),
            if (constraints.maxWidth >= 520) ...[
              SizedBox(
                width: 180,
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13.5, color: c.inkMuted),
                ),
              ),
              Expanded(child: valueText),
            ] else ...[
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13.5, color: c.inkMuted),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(child: valueText),
            ],
          ],
        ),
      ),
    );
  }
}

/// Titulo de seccion con accion opcional.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: c.inkFaint,
                letterSpacing: 1.05,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Estado vacío: icono y texto, sin contenedores.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        children: [
          Icon(icon, size: 34, color: c.inkFaint),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: c.ink,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.inkMuted, height: 1.4, fontSize: 13.5),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Banner de error no bloqueante.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.danger.withValues(alpha: context.isDark ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: c.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: c.danger,
                fontWeight: FontWeight.w500,
                height: 1.3,
                fontSize: 13.5,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: c.danger,
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chip de estado: color + etiqueta + icono (no depende solo del color).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = estadoStyle(context, label);
    final c = context.colors;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: c.chipAlpha),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: compact ? 12 : 13.5, color: style.color),
          const SizedBox(width: 5),
          Text(
            style.label,
            style: TextStyle(
              fontSize: compact ? 11.5 : 12.5,
              fontWeight: FontWeight.w600,
              color: style.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar de persona: la foto tal cual (círculo, sin marcos); si no hay
/// foto, iniciales como respaldo.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.fotoUrl,
    this.radius = 40,
    this.name,
  });

  final String? fotoUrl;
  final double radius;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final url = fotoUrl?.trim();
    if (url == null || url.isEmpty) {
      return ClipOval(
        child: InitialsAvatar(
          name: name ?? '?',
          size: radius * 2,
          color: context.colors.brand,
        ),
      );
    }
    return ClipOval(
      child: Image.network(
        url,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => InitialsAvatar(
          name: name ?? '?',
          size: radius * 2,
          color: context.colors.brand,
        ),
      ),
    );
  }
}

/// Logo de empresa: la imagen tal cual (círculo); si la empresa no tiene
/// logo, un símbolo genérico neutro.
class CompanyAvatar extends StatelessWidget {
  const CompanyAvatar({
    super.key,
    required this.fotoUrl,
    this.size = 44,
    this.name,
  });

  final String? fotoUrl;
  final double size;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final url = fotoUrl?.trim();
    // SVG y raster comparten el mismo encuadre; ante cualquier fallo se
    // conserva una identidad estable mediante iniciales.
    final isSvg = url?.toLowerCase().split('?').first.endsWith('.svg') ?? false;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: ColoredBox(
          color: context.isDark && isSvg ? const Color(0xFFF4F5F7) : c.surface,
          child: isSvg
              ? SvgPicture.network(
                  url,
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                  placeholderBuilder: (_) => _generic(c),
                  errorBuilder: (_, _, _) => _generic(c),
                )
              : Image.network(
                  url,
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => _generic(c),
                ),
        ),
      );
    }
    return _generic(c);
  }

  Widget _generic(LookUpColors c) {
    if ((name?.trim() ?? '').isNotEmpty) {
      return ClipOval(
        child: InitialsAvatar(name: name!, size: size, color: c.brand),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(size * 0.26),
      ),
      child: Icon(Icons.business_outlined, size: size * 0.5, color: c.inkFaint),
    );
  }
}

/// Página desplazable cuyo viewport ocupa todo el ancho disponible.
///
/// El scrollbar pertenece al borde de la ventana y solo se limita el ancho del
/// contenido. Es el patrón indicado para perfiles y detalles largos en web.
class ViewportScrollPage extends StatelessWidget {
  const ViewportScrollPage({
    super.key,
    required this.child,
    this.maxWidth = 1160,
    this.padding = const EdgeInsets.fromLTRB(22, 22, 22, 36),
    this.controller,
    this.physics,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      primary: controller == null,
      physics: physics,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Cabecera de perfil estilo profesional: banner de marca con el avatar
/// superpuesto, nombre, titular y una acción opcional.
class ProfileBanner extends StatelessWidget {
  const ProfileBanner({
    super.key,
    required this.avatar,
    required this.title,
    this.subtitle = '',
    this.caption = '',
    this.action,
    this.bannerUrl,
  });

  final Widget avatar;
  final String title;
  final String subtitle;
  final String caption;
  final Widget? action;
  final String? bannerUrl;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13.5, color: c.inkMuted),
              ),
            ],
            if (caption.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: c.inkFaint),
              ),
            ],
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                if ((bannerUrl?.trim() ?? '').isEmpty)
                  BrandGradientPanel(
                    height: compact ? 92 : 110,
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(12),
                    showBottomLeftRing: false,
                    child: const SizedBox.shrink(),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      bannerUrl!,
                      width: double.infinity,
                      height: compact ? 92 : 110,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => BrandGradientPanel(
                        height: compact ? 92 : 110,
                        padding: EdgeInsets.zero,
                        borderRadius: BorderRadius.circular(12),
                        showBottomLeftRing: false,
                        child: const SizedBox.shrink(),
                      ),
                    ),
                  ),
                Positioned(
                  left: compact ? 16 : 20,
                  bottom: -40,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: c.background,
                      shape: BoxShape.circle,
                    ),
                    child: avatar,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        details,
                        if (action != null) ...[
                          const SizedBox(height: 12),
                          action!,
                        ],
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: details),
                        if (action != null) ...[
                          const SizedBox(width: 12),
                          action!,
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Icon(icon, color: c.inkFaint, size: 19),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 13.5, color: c.inkMuted)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: c.ink,
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.only(top: 2, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: c.ink,
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
  const ErrorBanner({super.key, required this.message});

  final String message;

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
        borderRadius: BorderRadius.circular(7),
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
      return InitialsAvatar(
        name: name ?? '?',
        size: radius * 2,
        color: context.colors.brand,
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
  const CompanyAvatar({super.key, required this.fotoUrl, this.size = 44});

  final String? fotoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final url = fotoUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _generic(c),
        ),
      );
    }
    return _generic(c);
  }

  Widget _generic(LookUpColors c) {
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

/// Envuelve el contenido para limitar el ancho en pantallas grandes (web).
class PageContainer extends StatelessWidget {
  const PageContainer({super.key, required this.child, this.maxWidth = 1100});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
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
  });

  final Widget avatar;
  final String title;
  final String subtitle;
  final String caption;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: kBrandBlue,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            Positioned(
              left: 20,
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 13.5, color: c.inkMuted),
                      ),
                    ],
                    if (caption.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        caption,
                        style: TextStyle(fontSize: 12.5, color: c.inkFaint),
                      ),
                    ],
                  ],
                ),
              ),
              if (action != null) ...[const SizedBox(width: 12), action!],
            ],
          ),
        ),
      ],
    );
  }
}

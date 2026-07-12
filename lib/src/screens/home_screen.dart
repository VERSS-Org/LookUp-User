import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/services/auth_service.dart';
import 'package:lookup_user/src/services/data_service.dart';
import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/theme.dart';
import 'package:lookup_user/src/utils/formatters.dart';
import 'package:lookup_user/src/widgets/common.dart';

/// Inicio del postulante: saludo, resumen breve y novedades.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenTab,
    required this.onOpenMessages,
    required this.onOpenNotifications,
  });

  final ValueChanged<int> onOpenTab;
  final VoidCallback onOpenMessages;
  final VoidCallback onOpenNotifications;

  Future<void> _refresh(BuildContext context) async {
    final accountId = context.read<AuthService>().cuentaId;
    if (accountId != null) {
      await context.read<LookUpDataService>().refresh(accountId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final data = context.watch<LookUpDataService>();
    final c = context.colors;
    final name =
        auth.profile?['nombre_completo']?.toString().split(' ').first ??
        context.t('common.applicant');
    final enProceso = data.applications.where((a) {
      final estado = canonicalEstado(a['estado']?.toString() ?? '');
      return estado != 'rechazado' && estado != 'aceptado';
    }).length;

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: PageContainer(
        maxWidth: 860,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 32),
          children: [
            Text(
              '${context.t('home.greeting')} $name',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              context.t('home.subtitle'),
              style: TextStyle(color: c.inkMuted, fontSize: 15),
            ),
            const SizedBox(height: 20),
            if (data.error != null) ErrorBanner(message: data.error!),
            // Resumen breve en una sola franja, sin tarjetas.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: c.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _InlineStat(
                      value: data.applications.length.toString(),
                      label: context.t('home.applications'),
                    ),
                  ),
                  Container(width: 1, height: 34, color: c.border),
                  Expanded(
                    child: _InlineStat(
                      value: enProceso.toString(),
                      label: context.t('home.in_process'),
                    ),
                  ),
                  Container(width: 1, height: 34, color: c.border),
                  Expanded(
                    child: _InlineStat(
                      value: data.unreadMessages.toString(),
                      label: context.t('nav.messages'),
                      highlight: data.unreadMessages > 0,
                      onTap: onOpenMessages,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            SectionHeader(title: context.t('home.quick')),
            _QuickRow(
              icon: Icons.timeline_outlined,
              title: context.t('home.progress'),
              subtitle: context.t('home.progress.sub'),
              onTap: () => onOpenTab(2),
              badge: data.processAlerts,
            ),
            _QuickRow(
              icon: Icons.insights_outlined,
              title: context.t('home.metrics'),
              subtitle: context.t('home.metrics.sub'),
              onTap: () => onOpenTab(3),
            ),
            if (data.events.isNotEmpty) ...[
              const SizedBox(height: 26),
              SectionHeader(
                title: context.t('home.news'),
                actionLabel: context.t('home.news.all'),
                onAction: onOpenNotifications,
              ),
              ...data.events
                  .take(3)
                  .map(
                    (event) => _NotificationRow(
                      event: event,
                      onTap: onOpenNotifications,
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.event, required this.onTap});

  final Map<String, dynamic> event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.brand.withValues(alpha: c.chipAlpha),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                Icons.notifications_outlined,
                size: 18,
                color: c.brand,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['titulo']?.toString() ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    eventDescriptionT(context, event),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.inkMuted,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              relativeDateT(context, event['fecha']?.toString()),
              style: TextStyle(color: c.inkFaint, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  const _InlineStat({
    required this.value,
    required this.label,
    this.highlight = false,
    this.onTap,
  });

  final String value;
  final String label;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final content = Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: highlight ? c.accent : c.ink,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12.5, color: c.inkMuted),
        ),
      ],
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: content,
    );
  }
}

class _QuickRow extends StatelessWidget {
  const _QuickRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: c.brand),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                          fontSize: 15,
                        ),
                      ),
                      if (badge > 0) ...[
                        const SizedBox(width: 8),
                        Badge.count(count: badge),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: c.inkMuted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: c.inkFaint),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/services/auth_service.dart';
import 'package:lookup_user/src/services/data_service.dart';
import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/theme.dart';
import 'package:lookup_user/src/utils/formatters.dart';
import 'package:lookup_user/src/widgets/common.dart';

/// Progreso del postulante: contadores, tasa de exito y logros.
class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final data = context.watch<LookUpDataService>();
    final c = context.colors;
    final metrics = data.metrics ?? const <String, dynamic>{};
    final tasaExito = ((metrics['tasa_exito'] as num?)?.toDouble() ?? 0);

    return RefreshIndicator(
      onRefresh: () async {
        final cuentaId = auth.cuentaId;
        if (cuentaId != null) {
          await context.read<LookUpDataService>().fetchMetrics(cuentaId);
        }
      },
      child: PageContainer(
        maxWidth: 860,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
          children: [
            Text(
              context.t('metrics.header'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              context.t('metrics.sub'),
              style: TextStyle(color: c.inkMuted, fontSize: 14.5),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              decoration: BoxDecoration(
                color: c.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _Stat(
                      value: '${metrics['total_postulaciones'] ?? 0}',
                      label: context.t('metrics.applications'),
                      color: c.brand,
                    ),
                  ),
                  Container(width: 1, height: 40, color: c.border),
                  Expanded(
                    child: _Stat(
                      value: '${metrics['total_entrevistas'] ?? 0}',
                      label: context.t('metrics.interviews'),
                      color: c.accent,
                    ),
                  ),
                  Container(width: 1, height: 40, color: c.border),
                  Expanded(
                    child: _Stat(
                      value: '${metrics['total_exitos'] ?? 0}',
                      label: context.t('metrics.offers'),
                      color: c.success,
                    ),
                  ),
                  Container(width: 1, height: 40, color: c.border),
                  Expanded(
                    child: _Stat(
                      value: '${metrics['total_rechazos'] ?? 0}',
                      label: context.t('metrics.rejections'),
                      color: c.danger,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            SectionHeader(title: context.t('metrics.success')),
            Text(
              context.t('metrics.success.sub'),
              style: TextStyle(color: c.inkMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      backgroundColor: c.surfaceAlt,
                      valueColor: AlwaysStoppedAnimation(c.accent),
                      value: tasaExito.clamp(0, 100) / 100,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  '${tasaExito.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: c.brand,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            SectionHeader(title: context.t('metrics.achievements')),
            if (data.achievements.isEmpty)
              EmptyState(
                icon: Icons.emoji_events_outlined,
                title: context.t('metrics.achievements.empty.title'),
                message: context.t('metrics.achievements.empty.msg'),
              )
            else
              ...data.achievements.map(
                (logro) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: c.border)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, color: c.warning, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              logro['nombre_logro']?.toString() ?? '—',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: c.ink,
                                fontSize: 14.5,
                              ),
                            ),
                            Text(
                              '${context.t('metrics.goal')}: ${logro['umbral'] ?? '-'}',
                              style: TextStyle(color: c.inkMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatDate(logro['fecha_obtencion']),
                        style: TextStyle(color: c.inkFaint, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: c.inkMuted),
        ),
      ],
    );
  }
}

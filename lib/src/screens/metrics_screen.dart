import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/services/auth_service.dart';
import 'package:lookup_user/src/services/data_service.dart';
import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/theme.dart';
import 'package:lookup_user/src/utils/formatters.dart';
import 'package:lookup_user/src/widgets/common.dart';

class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final data = context.watch<LookUpDataService>();
    final c = context.colors;
    final metrics = data.metrics ?? const <String, dynamic>{};
    final total = asInt(
      metrics['total_postulaciones'],
      fallback: data.applications.length,
    );
    final interviews = asInt(
      metrics['total_entrevistas'],
      fallback: _countReached(data.applications, 'entrevista'),
    );
    final reviews = asInt(
      metrics['total_en_revision'],
      fallback: _countReached(data.applications, 'en_revision'),
    );
    final accepted = asInt(
      metrics['total_exitos'],
      fallback: _countReached(data.applications, 'aceptado'),
    );
    final rejected = asInt(
      metrics['total_rechazos'],
      fallback: _countReached(data.applications, 'rechazado'),
    );
    final rateValue = metrics['tasa_exito'];
    final parsedRate = rateValue is num
        ? rateValue.toDouble()
        : double.tryParse(rateValue?.toString() ?? '');
    final rate = (parsedRate ?? (total == 0 ? 0 : accepted * 100 / total))
        .clamp(0, 100);

    final successPanel = _SuccessRate(
      rate: rate.toDouble(),
      total: total,
      accepted: accepted,
    );
    final funnelPanel = _ApplicationFunnel(
      values: [
        (context.t('metrics.applications'), total, c.brand),
        (context.t('estado.en_revision'), reviews, kBrandBlueBright),
        (context.t('metrics.interviews'), interviews, c.accent),
        (context.t('metrics.offers'), accepted, c.success),
      ],
      rejected: rejected,
    );

    return RefreshIndicator(
      onRefresh: () async {
        final accountId = auth.cuentaId;
        if (accountId != null) {
          await context.read<LookUpDataService>().refresh(accountId);
        }
      },
      child: ViewportScrollPage(
        maxWidth: 900,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (data.error != null) ...[
              ErrorBanner(
                message: data.error!,
                actionLabel: context.t('common.retry'),
                onAction: () {
                  final accountId = auth.cuentaId;
                  if (accountId != null) {
                    context.read<LookUpDataService>().refresh(accountId);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
            Text(
              context.t('metrics.header'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              context.t('metrics.sub'),
              style: TextStyle(color: c.inkMuted, fontSize: 12.5),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 700) {
                  return Column(
                    children: [
                      successPanel,
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Divider(color: c.border, height: 1),
                      ),
                      funnelPanel,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: successPanel),
                    Container(
                      width: 1,
                      height: 190,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      color: c.border,
                    ),
                    Expanded(flex: 7, child: funnelPanel),
                  ],
                );
              },
            ),
            const SizedBox(height: 26),
            Divider(color: c.border, height: 1),
            const SizedBox(height: 20),
            SectionHeader(title: context.t('metrics.achievements')),
            if (data.achievementsError != null) ...[
              ErrorBanner(
                message: data.achievementsError!,
                actionLabel: context.t('common.retry'),
                onAction: () {
                  final accountId = auth.cuentaId;
                  if (accountId != null) {
                    context.read<LookUpDataService>().fetchMetrics(accountId);
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
            if (data.achievements.isEmpty && data.achievementsError == null)
              EmptyState(
                icon: Icons.emoji_events_outlined,
                title: context.t('metrics.achievements.empty.title'),
                message: context.t('metrics.achievements.empty.msg'),
              )
            else
              ...data.achievements.map(
                (achievement) => _AchievementRow(achievement: achievement),
              ),
          ],
        ),
      ),
    );
  }

  int _countReached(List<Map<String, dynamic>> applications, String target) {
    return applications.where((application) {
      if (canonicalEstado(application['estado']?.toString() ?? '') == target) {
        return true;
      }
      return asMapList(application['hitos']).any(
        (milestone) =>
            canonicalEstado(milestone['estado_nuevo']?.toString() ?? '') ==
            target,
      );
    }).length;
  }
}

class _SuccessRate extends StatelessWidget {
  const _SuccessRate({
    required this.rate,
    required this.total,
    required this.accepted,
  });

  final double rate;
  final int total;
  final int accepted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.t('metrics.success').toUpperCase(),
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: c.inkFaint),
        ),
        const SizedBox(height: 14),
        Center(
          child: SizedBox(
            width: 116,
            height: 116,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(116),
                  painter: _DonutPainter(
                    value: rate / 100,
                    background: c.surfaceAlt,
                    foreground: c.accent,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${rate.toStringAsFixed(1)}%',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 20),
                    ),
                    Text(
                      context.t('metrics.success.short'),
                      style: TextStyle(color: c.inkMuted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context
              .t('metrics.success.caption')
              .replaceAll('{accepted}', '$accepted')
              .replaceAll('{total}', '$total'),
          textAlign: TextAlign.center,
          style: TextStyle(color: c.inkMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.value,
    required this.background,
    required this.foreground,
  });

  final double value;
  final Color background;
  final Color foreground;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - 12) / 2;
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = background;
    final valuePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = foreground;
    canvas.drawCircle(center, radius, basePaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * value.clamp(0, 1),
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.background != background ||
        oldDelegate.foreground != foreground;
  }
}

class _ApplicationFunnel extends StatelessWidget {
  const _ApplicationFunnel({required this.values, required this.rejected});

  final List<(String, int, Color)> values;
  final int rejected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxValue = values.fold<int>(
      1,
      (current, item) => math.max(current, item.$2),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.t('metrics.funnel').toUpperCase(),
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: c.inkFaint),
        ),
        const SizedBox(height: 13),
        ...values.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    item.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.inkMuted, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      minHeight: 17,
                      value: item.$2 / maxValue,
                      backgroundColor: c.surfaceAlt,
                      color: item.$3,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                SizedBox(
                  width: 24,
                  child: Text(
                    '${item.$2}',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          context
              .t('metrics.funnel.caption')
              .replaceAll('{rejected}', '$rejected'),
          style: TextStyle(color: c.inkFaint, fontSize: 12),
        ),
      ],
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.achievement});

  final Map<String, dynamic> achievement;

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
          Icon(Icons.emoji_events, color: c.warning, size: 18),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              achievement['nombre_logro']?.toString() ?? '—',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: c.ink,
                fontSize: 12.5,
              ),
            ),
          ),
          Text(
            formatDate(achievement['fecha_obtencion']),
            style: TextStyle(color: c.inkFaint, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

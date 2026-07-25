import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/screens/company_screen.dart';
import 'package:lookup_user/src/screens/offers_screen.dart';
import 'package:lookup_user/src/services/auth_service.dart';
import 'package:lookup_user/src/services/data_service.dart';
import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/theme.dart';
import 'package:lookup_user/src/utils/formatters.dart';
import 'package:lookup_user/src/widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenProcesses,
    required this.onOpenOffers,
  });

  final VoidCallback onOpenProcesses;
  final VoidCallback onOpenOffers;

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
        auth.profile?['nombre_completo']?.toString().trim().split(' ').first ??
        context.t('common.applicant');
    final activeApplications = data.applications
        .where((application) {
          final state = canonicalEstado(
            application['estado']?.toString() ?? '',
          );
          return state != 'aceptado' && state != 'rechazado';
        })
        .take(2)
        .toList();
    final recommendationSource = data.recommendedJobs.isNotEmpty
        ? data.recommendedJobs
        : data.jobs;
    final suggestedJobs = recommendationSource
        .where(
          (job) =>
              (job['estado']?.toString() ?? 'abierto') == 'abierto' &&
              !data.hasAppliedTo(job['puesto_id']?.toString() ?? ''),
        )
        .take(2)
        .toList();

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: ViewportScrollPage(
        maxWidth: 980,
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 36),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${context.t('home.greeting')} $name',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              context
                  .t('home.subtitle.date')
                  .replaceAll('{date}', _todayLabel(context)),
              style: TextStyle(color: c.inkMuted, fontSize: 13),
            ),
            const SizedBox(height: 22),
            if (data.error != null) ErrorBanner(message: data.error!),
            _HomeSection(
              title: context.t('home.active_processes'),
              actionLabel: context.t('common.view_all'),
              onAction: onOpenProcesses,
              child: activeApplications.isEmpty
                  ? _CompactEmpty(
                      icon: Icons.route_outlined,
                      message: context.t('home.processes.empty'),
                    )
                  : Column(
                      children: activeApplications
                          .map(
                            (application) =>
                                _CompactProcessRow(application: application),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 28),
            _HomeSection(
              title: context.t('home.jobs_for_you'),
              actionLabel: context.t('common.view_all'),
              onAction: onOpenOffers,
              child: suggestedJobs.isEmpty
                  ? _CompactEmpty(
                      icon: Icons.work_outline,
                      message: context.t('home.jobs.empty'),
                    )
                  : Column(
                      children: suggestedJobs
                          .map(
                            (job) => JobRow(
                              job: job,
                              applied: false,
                              dense: true,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OfferDetailPage(job: job),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
            if (data.recommendedCompanies.isNotEmpty) ...[
              const SizedBox(height: 28),
              _HomeSection(
                title: context.t('home.companies_for_you'),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: data.recommendedCompanies
                      .take(4)
                      .map(
                        (company) => _RecommendedCompanyCard(
                          company: company,
                          onTap: () {
                            final companyId =
                                company['cuenta_id']?.toString() ??
                                company['empresa_id']?.toString() ??
                                '';
                            if (companyId.isEmpty) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CompanyScreen(empresaId: companyId),
                              ),
                            );
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _todayLabel(BuildContext context) {
    final date = DateTime.now();
    final language = context.read<LocaleController>().language;
    const weekdaysEs = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    const monthsEs = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    const weekdaysEn = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const monthsEn = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    if (language == 'en') {
      return '${weekdaysEn[date.weekday - 1]}, ${monthsEn[date.month - 1]} ${date.day}';
    }
    return '${weekdaysEs[date.weekday - 1]} ${date.day} de ${monthsEs[date.month - 1]}';
  }
}

class _HomeSection extends StatelessWidget {
  const _HomeSection({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: c.inkFaint,
                  letterSpacing: 1,
                ),
              ),
            ),
            if (actionLabel != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: Text(actionLabel!),
              ),
          ],
        ),
        const SizedBox(height: 3),
        child,
      ],
    );
  }
}

class _CompactProcessRow extends StatelessWidget {
  const _CompactProcessRow({required this.application});

  final Map<String, dynamic> application;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final position = asMap(application['puesto']);
    final company = asMap(application['empresa']);
    final state = canonicalEstado(
      application['estado']?.toString() ?? 'pendiente',
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              InitialsAvatar(
                name:
                    company['nombre']?.toString() ??
                    position['titulo']?.toString() ??
                    '?',
                size: 34,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      position['titulo']?.toString() ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      company['nombre']?.toString() ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.inkMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(label: state, compact: true),
            ],
          ),
          const SizedBox(height: 10),
          _MiniStageLine(state: state),
        ],
      ),
    );
  }
}

class _MiniStageLine extends StatelessWidget {
  const _MiniStageLine({required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final current = switch (state) {
      'en_revision' => 1,
      'entrevista' => 2,
      'aceptado' || 'rechazado' => 3,
      _ => 0,
    };
    return Row(
      children: List.generate(7, (index) {
        if (index.isOdd) {
          final step = index ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color: step < current
                  ? (step >= 1 ? c.warning : c.brand)
                  : c.border,
            ),
          );
        }
        final step = index ~/ 2;
        final reached = step <= current;
        final stepColor = switch (step) {
          1 || 2 => c.warning,
          3 when state == 'aceptado' => c.success,
          3 when state == 'rechazado' => c.danger,
          _ => c.brand,
        };
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: reached ? stepColor : c.background,
            shape: BoxShape.circle,
            border: Border.all(
              color: reached ? stepColor : c.border,
              width: 1.5,
            ),
          ),
          child: reached
              ? const Icon(Icons.check, size: 7, color: Colors.white)
              : null,
        );
      }),
    );
  }
}

class _RecommendedCompanyCard extends StatelessWidget {
  const _RecommendedCompanyCard({required this.company, required this.onTap});

  final Map<String, dynamic> company;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final name =
        company['nombre']?.toString() ??
        company['nombre_completo']?.toString() ??
        context.t('common.company');
    final reasons = company['razones'] is List
        ? List<dynamic>.from(company['razones'] as List)
        : const <dynamic>[];
    final detail = reasons.isNotEmpty
        ? reasons.first.toString()
        : company['ciudad']?.toString() ?? '';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            CompanyAvatar(
              fotoUrl:
                  company['foto_url']?.toString() ??
                  company['empresa_foto']?.toString(),
              name: name,
              size: 36,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.ink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (detail.isNotEmpty)
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.inkMuted, fontSize: 11.5),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 17, color: c.inkFaint),
          ],
        ),
      ),
    );
  }
}

class _CompactEmpty extends StatelessWidget {
  const _CompactEmpty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.colors.inkFaint),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: context.colors.inkMuted, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

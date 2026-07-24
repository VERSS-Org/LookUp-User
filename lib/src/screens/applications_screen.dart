import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/screens/messages_screen.dart';
import 'package:lookup_user/src/services/auth_service.dart';
import 'package:lookup_user/src/services/data_service.dart';
import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/theme.dart';
import 'package:lookup_user/src/utils/formatters.dart';
import 'package:lookup_user/src/widgets/common.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key, this.onOpenConversation});

  final ValueChanged<String>? onOpenConversation;

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  String _filter = 'todas';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final data = context.watch<LookUpDataService>();
    final active = data.applications.where(_isActive).length;
    final finished = data.applications.length - active;
    final filtered = data.applications.where((application) {
      return switch (_filter) {
        'activas' => _isActive(application),
        'finalizadas' => !_isActive(application),
        _ => true,
      };
    }).toList();

    return Material(
      color: Colors.transparent,
      child: RefreshIndicator(
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
                context.t('apps.title'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      value: 'todas',
                      label: context.t('apps.filter.all'),
                      count: data.applications.length,
                      selected: _filter == 'todas',
                      onSelected: () => setState(() => _filter = 'todas'),
                    ),
                    _FilterChip(
                      value: 'activas',
                      label: context.t('apps.filter.active'),
                      count: active,
                      selected: _filter == 'activas',
                      onSelected: () => setState(() => _filter = 'activas'),
                    ),
                    _FilterChip(
                      value: 'finalizadas',
                      label: context.t('apps.filter.finished'),
                      count: finished,
                      selected: _filter == 'finalizadas',
                      onSelected: () => setState(() => _filter = 'finalizadas'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (filtered.isEmpty)
                EmptyState(
                  icon: Icons.fact_check_outlined,
                  title: data.applications.isEmpty
                      ? context.t('apps.empty.title')
                      : context.t('apps.filter.empty'),
                  message: context.t('apps.empty.msg'),
                )
              else
                ...filtered.map(
                  (application) => _ApplicationBlock(
                    application: application,
                    onOpenConversation: widget.onOpenConversation,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isActive(Map<String, dynamic> application) {
    final state = canonicalEstado(application['estado']?.toString() ?? '');
    return state != 'aceptado' && state != 'rechazado';
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.value,
    required this.label,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  final String value;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: ChoiceChip(
        key: Key('applications-filter-$value'),
        label: Text('$label · $count'),
        selected: selected,
        selectedColor: const Color(0xFF2C3CA6),
        backgroundColor: c.surface,
        labelStyle: TextStyle(color: selected ? Colors.white : c.inkMuted),
        side: BorderSide(color: selected ? Colors.transparent : c.border),
        showCheckmark: false,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _ApplicationBlock extends StatelessWidget {
  const _ApplicationBlock({required this.application, this.onOpenConversation});

  final Map<String, dynamic> application;
  final ValueChanged<String>? onOpenConversation;

  Future<void> _confirmWithdrawal(
    BuildContext context,
    String applicationId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('withdraw.confirm.title')),
        content: Text(context.tr('withdraw.confirm.msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('common.cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.danger,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('withdraw.action')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final accountId = context.read<AuthService>().cuentaId;
    if (accountId == null) return;
    try {
      await context.read<LookUpDataService>().withdrawApplication(
        accountId,
        applicationId,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('withdraw.done'))));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final data = context.watch<LookUpDataService>();
    final position = asMap(application['puesto']);
    final company = asMap(application['empresa']);
    final milestones = asMapList(application['hitos']);
    final applicationId = application['postulacion_id']?.toString() ?? '';
    final state = canonicalEstado(
      application['estado']?.toString() ?? 'pendiente',
    );
    final hasChat = data.inbox.any(
      (thread) => thread['postulacion_id']?.toString() == applicationId,
    );
    final lastMilestone = milestones.isEmpty ? null : milestones.last;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InitialsAvatar(
                name:
                    company['nombre']?.toString() ??
                    position['titulo']?.toString() ??
                    '?',
                size: 38,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      position['titulo']?.toString() ?? '—',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${company['nombre'] ?? '—'} · '
                      '${context.t('apps.applied_on')} '
                      '${formatDate(application['fecha_postulacion'])}',
                      style: TextStyle(color: c.inkMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ProcessStepper(state: state),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              final update = lastMilestone == null
                  ? context.t('apps.no_updates')
                  : '${context.t('apps.last_update')}: '
                        '${eventDescriptionT(context, lastMilestone)} · '
                        '${formatDate(lastMilestone['fecha'])}';
              final updateText = Text(
                update,
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c.inkFaint, fontSize: 12),
              );
              final actions = Wrap(
                alignment: WrapAlignment.end,
                spacing: 2,
                runSpacing: 2,
                children: [
                  if (hasChat)
                    TextButton.icon(
                      key: Key('application-open-chat-$applicationId'),
                      onPressed: () {
                        if (onOpenConversation != null) {
                          onOpenConversation!(applicationId);
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MessagesScreen(
                              initialPostulacionId: applicationId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_outlined, size: 14),
                      label: Text(context.tr('apps.open_chat')),
                    ),
                  if (LookUpDataService.estadosRetirables.contains(state))
                    TextButton.icon(
                      onPressed: () =>
                          _confirmWithdrawal(context, applicationId),
                      style: TextButton.styleFrom(foregroundColor: c.danger),
                      icon: const Icon(Icons.close, size: 14),
                      label: Text(context.tr('withdraw.action')),
                    ),
                ],
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    updateText,
                    const SizedBox(height: 3),
                    Align(alignment: Alignment.centerRight, child: actions),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: updateText),
                  const SizedBox(width: 10),
                  actions,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProcessStepper extends StatelessWidget {
  const _ProcessStepper({required this.state});

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
    final failed = state == 'rechazado';
    final labels = [
      context.t('apps.stage.sent'),
      context.t('estado.en_revision'),
      context.t('estado.entrevista'),
      failed
          ? context.t('estado.rechazado')
          : state == 'aceptado'
          ? context.t('estado.aceptado')
          : context.t('apps.stage.result'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 460;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(7, (index) {
            if (index.isOdd) {
              final step = index ~/ 2;
              return Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(top: 7),
                  color: step < current ? c.brand : c.border,
                ),
              );
            }
            final step = index ~/ 2;
            final reached = step <= current;
            final terminalColor = failed && step == 3 ? c.danger : c.brand;
            return SizedBox(
              width: compact ? 58 : 86,
              child: Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: reached ? terminalColor : c.background,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: reached ? terminalColor : c.border,
                        width: 1.5,
                      ),
                    ),
                    child: reached
                        ? Icon(
                            failed && step == 3 ? Icons.close : Icons.check,
                            size: 10,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    labels[step],
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: reached ? terminalColor : c.inkFaint,
                      fontSize: 12,
                      fontWeight: reached ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

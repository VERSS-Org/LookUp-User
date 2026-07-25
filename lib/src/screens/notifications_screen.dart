import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/screens/applications_screen.dart';
import 'package:lookup_user/src/screens/company_screen.dart';
import 'package:lookup_user/src/screens/messages_screen.dart';
import 'package:lookup_user/src/screens/offers_screen.dart';
import 'package:lookup_user/src/services/data_service.dart';
import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/theme.dart';
import 'package:lookup_user/src/utils/formatters.dart';
import 'package:lookup_user/src/widgets/common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.embedded = false,
    this.onOpenJob,
    this.onOpenProcesses,
    this.onOpenConversation,
    this.onOpenCompany,
  });

  final bool embedded;
  final ValueChanged<String>? onOpenJob;
  final VoidCallback? onOpenProcesses;
  final ValueChanged<String>? onOpenConversation;
  final ValueChanged<String>? onOpenCompany;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? _loadError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      await context.read<LookUpDataService>().fetchEvents();
    } catch (error) {
      if (mounted) setState(() => _loadError = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markRead() {
    return context.read<LookUpDataService>().markNotificationsSeen();
  }

  Future<void> _openNotification(Map<String, dynamic> event) async {
    try {
      await context.read<LookUpDataService>().markNotificationSeen(event);
    } catch (error) {
      // Un fallo al marcarla no debe bloquear el destino principal.
      debugPrint('Could not mark notification as read: $error');
    }
    if (!mounted) return;

    final destination = _notificationDestination(event);
    if (destination == null) return;
    switch (destination.type) {
      case _NotificationDestinationType.job:
        final puestoId = destination.id;
        if (puestoId == null) return;
        final callback = widget.onOpenJob;
        if (callback != null) {
          callback(puestoId);
        } else {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OfferDetailPage(
                job: {
                  'puesto_id': puestoId,
                  'titulo': event['titulo']?.toString() ?? '',
                  'empresa_id': ?_eventId(event, const ['empresa_id']),
                },
              ),
            ),
          );
        }
        return;
      case _NotificationDestinationType.processes:
        final callback = widget.onOpenProcesses;
        if (callback != null) {
          callback();
        } else {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ApplicationsScreen()));
        }
        return;
      case _NotificationDestinationType.conversation:
        final postulacionId = destination.id;
        if (postulacionId == null) return;
        final callback = widget.onOpenConversation;
        if (callback != null) {
          callback(postulacionId);
        } else {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  MessagesScreen(initialPostulacionId: postulacionId),
            ),
          );
        }
        return;
      case _NotificationDestinationType.company:
        final empresaId = destination.id;
        if (empresaId == null) return;
        final callback = widget.onOpenCompany;
        if (callback != null) {
          callback(empresaId);
        } else {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CompanyScreen(empresaId: empresaId),
            ),
          );
        }
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<LookUpDataService>();
    final c = context.colors;
    final events = data.events;

    final pageBody = RefreshIndicator(
      onRefresh: _refresh,
      child: ViewportScrollPage(
        maxWidth: 820,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_loadError != null)
              _LoadErrorPanel(message: _loadError!, onRetry: _refresh),
            if (_isLoading && events.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              )
            else if (events.isEmpty && _loadError == null)
              EmptyState(
                icon: Icons.notifications_none,
                title: context.t('notif.empty.title'),
                message: context.t('notif.empty.msg'),
              )
            else ...[
              for (var index = 0; index < events.length; index++) ...[
                _NotificationItem(
                  event: events[index],
                  onTap: () => _openNotification(events[index]),
                ),
                if (index < events.length - 1)
                  Divider(color: c.border, height: 1, indent: 44),
              ],
            ],
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return Material(
        color: Colors.transparent,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.t('notif.title'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  TextButton(
                    key: const Key('notifications-mark-read'),
                    onPressed: data.unseenNotifications == 0 ? null : _markRead,
                    child: Text(context.t('notif.mark_read')),
                  ),
                ],
              ),
            ),
            Divider(color: c.border, height: 1),
            Expanded(child: pageBody),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: context.t('common.back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.t('notif.title')),
        actions: [
          TextButton(
            key: const Key('notifications-mark-read'),
            onPressed: data.unseenNotifications == 0 ? null : _markRead,
            child: Text(context.t('notif.mark_read')),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: pageBody,
    );
  }
}

class _LoadErrorPanel extends StatelessWidget {
  const _LoadErrorPanel({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ErrorBanner(message: message),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 17),
            label: Text(context.t('common.retry')),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({required this.event, required this.onTap});

  final Map<String, dynamic> event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type =
        event['tipo_evento']?.toString() ?? event['tipo']?.toString() ?? '';
    final metadata = asMap(event['metadata']);
    final state = canonicalEstado(
      (event['estado_nuevo'] ?? metadata['estado_nuevo'] ?? metadata['estado'])
              ?.toString() ??
          '',
    );
    final visual = switch ((type, state)) {
      ('postulacion_creada' || 'nueva_postulacion', _) => (
        icon: Icons.send_outlined,
        color: c.brand,
      ),
      ('estado_actualizado' || 'estado_postulacion', 'entrevista') => (
        icon: Icons.event_available_outlined,
        color: c.warning,
      ),
      ('vacante_guardada_cerrada', _) => (
        icon: Icons.bookmark_remove_outlined,
        color: c.danger,
      ),
      ('nueva_vacante_empresa_seguida', _) => (
        icon: Icons.work_outline,
        color: c.accent,
      ),
      ('estado_actualizado' || 'estado_postulacion', 'aceptado') => (
        icon: Icons.emoji_events_outlined,
        color: c.success,
      ),
      ('estado_actualizado' || 'estado_postulacion', 'rechazado') => (
        icon: Icons.cancel_outlined,
        color: c.danger,
      ),
      _ => (icon: Icons.assignment_turned_in_outlined, color: c.warning),
    };

    return Material(
      color: event['leida'] == false
          ? c.brand.withValues(alpha: .045)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(visual.icon, size: 17, color: visual.color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prettyEventText(
                        context,
                        event['titulo']?.toString() ?? '—',
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (event['mensaje']?.toString().trim() ?? '').isNotEmpty
                          ? event['mensaje'].toString()
                          : eventDescriptionT(context, event),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.inkMuted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                relativeDateT(
                  context,
                  (event['fecha'] ?? event['fecha_creacion'])?.toString(),
                ),
                style: TextStyle(color: c.inkFaint, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _NotificationDestinationType { job, processes, conversation, company }

typedef _NotificationDestination = ({
  _NotificationDestinationType type,
  String? id,
});

_NotificationDestination? _notificationDestination(Map<String, dynamic> event) {
  final type =
      (event['tipo'] ?? event['tipo_evento'])?.toString().toLowerCase() ?? '';
  final postulacionId = _eventId(event, const [
    'postulacion_id',
    'application_id',
  ]);
  final puestoId = _eventId(event, const ['puesto_id', 'vacante_id', 'job_id']);
  final empresaId = _eventId(event, const ['empresa_id', 'company_id']);

  // Una vacante cerrada ya no es visible para el postulante. Su empresa sigue
  // siendo un destino útil; si tampoco está identificada, la fila solo se
  // marca como leída y permanece en el centro de notificaciones.
  if (type == 'vacante_guardada_cerrada') {
    return empresaId == null
        ? null
        : (type: _NotificationDestinationType.company, id: empresaId);
  }

  final isConversation =
      type.contains('mensaje') ||
      type.contains('chat') ||
      type.contains('conversacion');
  if (isConversation && postulacionId != null) {
    return (type: _NotificationDestinationType.conversation, id: postulacionId);
  }

  final isProcess =
      type.contains('postulacion') ||
      type.contains('estado_actualizado') ||
      type.contains('proceso');
  if (isProcess) {
    return (type: _NotificationDestinationType.processes, id: postulacionId);
  }
  if (puestoId != null) {
    return (type: _NotificationDestinationType.job, id: puestoId);
  }
  if (empresaId != null) {
    return (type: _NotificationDestinationType.company, id: empresaId);
  }
  if (postulacionId != null) {
    return (type: _NotificationDestinationType.processes, id: postulacionId);
  }
  return null;
}

String? _eventId(Map<String, dynamic> event, List<String> keys) {
  final metadata = asMap(event['metadata']);
  for (final source in [event, metadata]) {
    for (final key in keys) {
      final value = source[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
  }
  return null;
}

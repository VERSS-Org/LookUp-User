import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/services/data_service.dart';
import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/theme.dart';
import 'package:lookup_user/src/utils/formatters.dart';
import 'package:lookup_user/src/widgets/common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.popup = false});

  final bool popup;

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

  @override
  Widget build(BuildContext context) {
    final data = context.watch<LookUpDataService>();
    final c = context.colors;
    final events = data.events;
    final popupList = RefreshIndicator(
      onRefresh: _refresh,
      child: _isLoading && events.isEmpty
          ? ListView(
              children: const [
                Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            )
          : events.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(22),
              children: [
                if (_loadError != null)
                  _LoadErrorPanel(message: _loadError!, onRetry: _refresh)
                else
                  EmptyState(
                    icon: Icons.notifications_none,
                    title: context.t('notif.empty.title'),
                    message: context.t('notif.empty.msg'),
                  ),
              ],
            )
          : ListView.separated(
              padding: EdgeInsets.symmetric(
                vertical: widget.popup ? 4 : 12,
                horizontal: widget.popup ? 0 : 16,
              ),
              itemCount: events.length,
              separatorBuilder: (_, _) => Divider(
                color: c.border,
                height: 1,
                indent: widget.popup ? 48 : 44,
              ),
              itemBuilder: (context, index) =>
                  _NotificationItem(event: events[index]),
            ),
    );

    if (widget.popup) {
      return Material(
        color: c.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.border),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 10, 7),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.t('notif.title'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    key: const Key('notifications-mark-read'),
                    onPressed: data.unseenNotifications == 0 ? null : _markRead,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    child: Text(context.t('notif.mark_read')),
                  ),
                ],
              ),
            ),
            Divider(color: c.border, height: 1),
            if (_loadError != null && events.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 0),
                child: _LoadErrorPanel(
                  message: _loadError!,
                  onRetry: _refresh,
                  compact: true,
                ),
              ),
            Expanded(child: popupList),
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
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ViewportScrollPage(
          maxWidth: 720,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
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
                  _NotificationItem(event: events[index]),
                  if (index < events.length - 1)
                    Divider(color: c.border, height: 1, indent: 44),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadErrorPanel extends StatelessWidget {
  const _LoadErrorPanel({
    required this.message,
    required this.onRetry,
    this.compact = false,
  });

  final String message;
  final Future<void> Function() onRetry;
  final bool compact;

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
        if (!compact) const SizedBox(height: 8),
      ],
    );
  }
}

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({required this.event});

  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = event['tipo_evento']?.toString() ?? '';
    final state = canonicalEstado(event['estado_nuevo']?.toString() ?? '');
    final visual = switch ((type, state)) {
      ('postulacion_creada', _) => (icon: Icons.send_outlined, color: c.brand),
      ('estado_actualizado', 'entrevista') => (
        icon: Icons.event_available_outlined,
        color: c.accent,
      ),
      ('estado_actualizado', 'aceptado') => (
        icon: Icons.emoji_events_outlined,
        color: c.success,
      ),
      ('estado_actualizado', 'rechazado') => (
        icon: Icons.cancel_outlined,
        color: c.danger,
      ),
      _ => (icon: Icons.assignment_turned_in_outlined, color: c.warning),
    };

    return Padding(
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
                  prettyEventText(context, event['titulo']?.toString() ?? '—'),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: c.ink,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  eventDescriptionT(context, event),
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
            relativeDateT(context, event['fecha']?.toString()),
            style: TextStyle(color: c.inkFaint, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

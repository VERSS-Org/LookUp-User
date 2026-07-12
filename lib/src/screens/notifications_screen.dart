import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/services/data_service.dart';
import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/theme.dart';
import 'package:lookup_user/src/utils/formatters.dart';
import 'package:lookup_user/src/widgets/common.dart';

/// Notificaciones: novedades de los procesos de los últimos 7 días.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.popup = false});

  /// true cuando se presenta como panel flotante desde la campana web.
  final bool popup;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final data = context.read<LookUpDataService>();
      await data.fetchEvents();
      await data.markNotificationsSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<LookUpDataService>();
    final c = context.colors;
    final events = data.events;

    final body = RefreshIndicator(
      onRefresh: () async {
        final data = context.read<LookUpDataService>();
        await data.fetchEvents();
        await data.markNotificationsSeen();
      },
      child: PageContainer(
        maxWidth: 700,
        child: events.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  EmptyState(
                    icon: Icons.notifications_none,
                    title: context.t('notif.empty.title'),
                    message: context.t('notif.empty.msg'),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: events.length,
                separatorBuilder: (_, index) =>
                    Divider(color: c.border, height: 1, indent: 56),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          size: 20,
                          color: c.inkFaint,
                        ),
                        const SizedBox(width: 14),
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
                                  fontWeight: FontWeight.w600,
                                  color: c.ink,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                eventDescriptionT(context, event),
                                style: TextStyle(
                                  color: c.inkMuted,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          relativeDateT(context, event['fecha']?.toString()),
                          style: TextStyle(color: c.inkFaint, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );

    if (widget.popup) {
      return Material(
        color: c.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.border),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.t('notif.title'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: context.t('common.close'),
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(color: c.border, height: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          tooltip: context.t('common.back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.t('notif.title')),
      ),
      body: body,
    );
  }
}

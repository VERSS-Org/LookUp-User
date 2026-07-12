import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/services/data_service.dart';
import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/theme.dart';
import 'package:lookup_user/src/utils/formatters.dart';
import 'package:lookup_user/src/widgets/common.dart';

/// Notificaciones: novedades de los procesos de los últimos 7 días.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.embedded = false});

  /// true cuando se muestra dentro del shell web (sin flecha de volver).
  final bool embedded;

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

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: !widget.embedded,
        leading: widget.embedded
            ? null
            : IconButton(
                tooltip: context.t('common.back'),
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(context.t('notif.title')),
      ),
      body: RefreshIndicator(
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
                                  event['titulo']?.toString() ?? '—',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: c.ink,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  prettyEventText(
                                    context,
                                    event['descripcion']?.toString() ?? '',
                                  ),
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
      ),
    );
  }
}

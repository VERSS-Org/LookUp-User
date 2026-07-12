import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/screens/messages_screen.dart';
import 'package:lookup_user/src/services/auth_service.dart';
import 'package:lookup_user/src/services/data_service.dart';
import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/theme.dart';
import 'package:lookup_user/src/utils/formatters.dart';
import 'package:lookup_user/src/widgets/common.dart';

/// Procesos del postulante: cada postulación con su avance y acceso al chat.
class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final data = context.watch<LookUpDataService>();

    return RefreshIndicator(
      onRefresh: () async {
        final cuentaId = auth.cuentaId;
        if (cuentaId != null) {
          await context.read<LookUpDataService>().fetchApplications(cuentaId);
        }
      },
      child: PageContainer(
        maxWidth: 860,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
          children: [
            Text(
              context.t('apps.title'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 14),
            if (data.applications.isEmpty)
              EmptyState(
                icon: Icons.fact_check_outlined,
                title: context.t('apps.empty.title'),
                message: context.t('apps.empty.msg'),
              )
            else
              ...data.applications.map(
                (application) => _ApplicationBlock(application: application),
              ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationBlock extends StatelessWidget {
  const _ApplicationBlock({required this.application});

  final Map<String, dynamic> application;

  Future<void> _confirmarRetiro(
    BuildContext context,
    String postulacionId,
  ) async {
    final confirmado = await showDialog<bool>(
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
    if (confirmado != true || !context.mounted) return;

    final cuentaId = context.read<AuthService>().cuentaId;
    if (cuentaId == null) return;
    try {
      await context.read<LookUpDataService>().withdrawApplication(
        cuentaId,
        postulacionId,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('withdraw.done'))));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
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
    final puesto = asMap(application['puesto']);
    final empresa = asMap(application['empresa']);
    final hitos = asMapList(application['hitos']);
    final postulacionId = application['postulacion_id']?.toString() ?? '';
    final tieneChat = data.inbox.any(
      (hilo) => hilo['postulacion_id']?.toString() == postulacionId,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompanyAvatar(fotoUrl: empresa['foto_url']?.toString(), size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      puesto['titulo']?.toString() ?? '—',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${empresa['nombre'] ?? '—'} · ${context.t('apps.applied_on')} ${formatDate(application['fecha_postulacion'])}',
                      style: TextStyle(color: c.inkMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: application['estado']?.toString() ?? 'pendiente',
              ),
            ],
          ),
          if (hitos.isNotEmpty) ...[
            const SizedBox(height: 14),
            _Timeline(items: hitos.take(3).toList()),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              if (tieneChat)
                TextButton.icon(
                  onPressed: () {
                    final hilo = data.inbox.firstWhere(
                      (h) => h['postulacion_id']?.toString() == postulacionId,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChatScreen(hilo: hilo)),
                    );
                  },
                  icon: const Icon(Icons.chat_outlined, size: 17),
                  label: Text(context.tr('apps.open_chat')),
                ),
              const Spacer(),
              if (LookUpDataService.estadosRetirables.contains(
                canonicalEstado(application['estado']?.toString() ?? ''),
              ))
                TextButton.icon(
                  onPressed: () => _confirmarRetiro(context, postulacionId),
                  style: TextButton.styleFrom(foregroundColor: c.danger),
                  icon: const Icon(Icons.close, size: 16),
                  label: Text(context.tr('withdraw.action')),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: List.generate(items.length, (i) {
        final hito = items[i];
        final isLast = i == items.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 12),
              Column(
                children: [
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: i == 0 ? c.accent : c.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: i == 0 ? c.accent : c.inkFaint,
                        width: 2,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        color: c.border,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatDate(hito['fecha']),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: c.inkFaint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        hito['descripcion']?.toString() ?? '—',
                        style: TextStyle(
                          color: c.ink,
                          height: 1.35,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

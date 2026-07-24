import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/screens/offers_screen.dart';
import 'package:lookup_user/src/services/data_service.dart';
import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/theme.dart';
import 'package:lookup_user/src/widgets/common.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key, required this.empresaId});

  final String empresaId;

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  late Future<(Map<String, dynamic>?, List<Map<String, dynamic>>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(Map<String, dynamic>?, List<Map<String, dynamic>>)> _load() async {
    final data = context.read<LookUpDataService>();
    final results = await Future.wait([
      data.fetchCuenta(widget.empresaId),
      data.fetchJobsByCompany(widget.empresaId),
    ]);
    return (
      results[0] as Map<String, dynamic>?,
      results[1] as List<Map<String, dynamic>>,
    );
  }

  void _retry() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final data = context.watch<LookUpDataService>();
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 44,
        title: Text(context.t('company.title')),
      ),
      body: FutureBuilder<(Map<String, dynamic>?, List<Map<String, dynamic>>)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ViewportScrollPage(
              maxWidth: 720,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  ErrorBanner(message: snapshot.error.toString()),
                  EmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: context.t('common.error.connection'),
                    message: context.t('chat.retry.msg'),
                    actionLabel: context.t('common.retry'),
                    onAction: _retry,
                  ),
                ],
              ),
            );
          }
          final company = snapshot.data?.$1 ?? const <String, dynamic>{};
          final jobs = snapshot.data?.$2 ?? const [];
          final name =
              company['nombre_completo']?.toString() ??
              context.t('common.company');
          final details = company['perfil'] is Map
              ? Map<String, dynamic>.from(company['perfil'] as Map)
              : const <String, dynamic>{};
          final description = details['descripcion']?.toString().trim() ?? '';
          final city = company['ciudad']?.toString().trim() ?? '';
          final phone = company['telefono']?.toString().trim() ?? '';

          return ViewportScrollPage(
            key: const Key('company-profile-scroll'),
            maxWidth: 860,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileBanner(
                  avatar: CompanyAvatar(
                    fotoUrl: company['foto_url']?.toString(),
                    size: 76,
                  ),
                  title: name,
                  subtitle: city,
                  caption: phone,
                ),
                const SizedBox(height: 24),
                SectionHeader(title: context.t('company.about')),
                Text(
                  description.isEmpty
                      ? context.t('company.about.empty')
                      : description,
                  style: TextStyle(
                    color: description.isEmpty ? c.inkFaint : c.ink,
                    height: 1.55,
                    fontSize: 12.5,
                    fontStyle: description.isEmpty ? FontStyle.italic : null,
                  ),
                ),
                const SizedBox(height: 24),
                SectionHeader(
                  title: '${context.t('company.openings')} · ${jobs.length}',
                ),
                if (jobs.isEmpty)
                  EmptyState(
                    icon: Icons.work_off_outlined,
                    title: context.t('offers.empty.title'),
                    message: context.t('company.no_openings'),
                  )
                else
                  ...jobs.map(
                    (job) => JobRow(
                      job: job,
                      applied: data.hasAppliedTo(
                        job['puesto_id']?.toString() ?? '',
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OfferDetailPage(job: job),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

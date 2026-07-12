import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/screens/offers_screen.dart';
import 'package:lookup_user/src/services/data_service.dart';
import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/theme.dart';
import 'package:lookup_user/src/widgets/common.dart';

/// Perfil público de una empresa: descripción y vacantes abiertas.
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
    final data = context.read<LookUpDataService>();
    _future = () async {
      final resultados = await Future.wait([
        data.fetchCuenta(widget.empresaId),
        data.fetchJobsByCompany(widget.empresaId),
      ]);
      return (
        resultados[0] as Map<String, dynamic>?,
        resultados[1] as List<Map<String, dynamic>>,
      );
    }();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final data = context.watch<LookUpDataService>();

    return Scaffold(
      appBar: AppBar(title: Text(context.t('company.title'))),
      body: FutureBuilder<(Map<String, dynamic>?, List<Map<String, dynamic>>)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final empresa = snapshot.data?.$1 ?? const <String, dynamic>{};
          final vacantes = snapshot.data?.$2 ?? const [];
          final nombre =
              empresa['nombre_completo']?.toString() ??
              context.t('common.company');
          final perfil = empresa['perfil'] is Map
              ? Map<String, dynamic>.from(empresa['perfil'] as Map)
              : const <String, dynamic>{};
          final descripcion = perfil['descripcion']?.toString() ?? '';
          final ciudad = empresa['ciudad']?.toString() ?? '';

          return PageContainer(
            maxWidth: 760,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
              children: [
                ProfileBanner(
                  avatar: CompanyAvatar(
                    fotoUrl: empresa['foto_url']?.toString(),
                    size: 88,
                  ),
                  title: nombre,
                  subtitle: ciudad,
                  caption: empresa['email']?.toString() ?? '',
                ),
                const SizedBox(height: 6),
                if (descripcion.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  SectionHeader(title: context.t('company.about')),
                  Text(
                    descripcion,
                    style: TextStyle(
                      color: c.ink,
                      height: 1.55,
                      fontSize: 14.5,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SectionHeader(
                  title:
                      '${context.t('company.openings')} (${vacantes.length})',
                ),
                if (vacantes.isEmpty)
                  EmptyState(
                    icon: Icons.work_off_outlined,
                    title: context.t('offers.empty.title'),
                    message: context.t('company.no_openings'),
                  )
                else
                  ...vacantes.map(
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

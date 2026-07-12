import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/screens/company_screen.dart';
import 'package:lookup_user/src/services/auth_service.dart';
import 'package:lookup_user/src/services/data_service.dart';
import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/theme.dart';
import 'package:lookup_user/src/utils/formatters.dart';
import 'package:lookup_user/src/widgets/common.dart';

/// Listado plano de vacantes; el detalle se abre desde cada fila.
class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key, this.onClearSearch});

  final VoidCallback? onClearSearch;

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  List<Map<String, dynamic>> _companies = [];
  int _searchStamp = 0;
  String _companyQuery = '';
  bool _isSearchingCompanies = false;

  Future<void> _searchCompanies(String value) async {
    final stamp = ++_searchStamp;
    if (value.trim().length < 2) {
      if (_companies.isNotEmpty || _isSearchingCompanies) {
        setState(() {
          _companies = [];
          _isSearchingCompanies = false;
        });
      }
      return;
    }
    setState(() {
      _companies = [];
      _isSearchingCompanies = true;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted || stamp != _searchStamp) return;
    final resultados = await context.read<LookUpDataService>().searchCompanies(
      value,
    );
    if (!mounted || stamp != _searchStamp) return;
    setState(() {
      _companies = resultados;
      _isSearchingCompanies = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<LookUpDataService>();
    final c = context.colors;
    final query = data.searchQuery;
    if (_companyQuery != query) {
      _companyQuery = query;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchCompanies(query);
      });
    }
    final normalizedQuery = normalizeSearchText(query);
    final filtered = data.jobs.where((job) {
      final text = normalizeSearchText(
        '${job['titulo']} ${job['descripcion']} ${job['ubicacion']} ${job['empresa_nombre'] ?? ''}',
      );
      return text.contains(normalizedQuery);
    }).toList();

    return RefreshIndicator(
      onRefresh: () => context.read<LookUpDataService>().fetchJobs(),
      child: PageContainer(
        maxWidth: 860,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
          children: [
            Text(
              context.t('offers.title'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (query.isNotEmpty) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${context.t('search.results_for')} "$query"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.inkMuted, fontSize: 13.5),
                    ),
                  ),
                  TextButton.icon(
                    onPressed:
                        widget.onClearSearch ?? () => data.setSearchQuery(''),
                    icon: const Icon(Icons.close, size: 17),
                    label: Text(context.t('search.clear')),
                  ),
                ],
              ),
            ],
            if (query.trim().length >= 2 &&
                (_companies.isNotEmpty || _isSearchingCompanies)) ...[
              const SizedBox(height: 12),
              SectionHeader(title: context.t('search.companies')),
              if (_isSearchingCompanies)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              ..._companies.map(
                (empresa) => _CompanyRow(
                  empresa: empresa,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CompanyScreen(
                        empresaId: empresa['cuenta_id'].toString(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
            if (query.isNotEmpty)
              SectionHeader(title: context.t('search.vacancies')),
            const SizedBox(height: 8),
            if (query.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${filtered.length} ${filtered.length == 1 ? context.t('offers.result') : context.t('offers.results')}',
                  style: TextStyle(color: c.inkFaint, fontSize: 13),
                ),
              ),
            if (data.isLoading && data.jobs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: EmptyState(
                  icon: Icons.work_off_outlined,
                  title: query.isEmpty
                      ? context.t('offers.empty.title')
                      : '"$query"',
                  message: query.isEmpty
                      ? context.t('offers.empty.msg')
                      : context.t('offers.no_results.msg'),
                ),
              )
            else
              ...filtered.map(
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
      ),
    );
  }
}

/// Fila de vacante: sobria, sin tarjeta, separada por una línea.
class JobRow extends StatelessWidget {
  const JobRow({
    super.key,
    required this.job,
    required this.applied,
    required this.onTap,
  });

  final Map<String, dynamic> job;
  final bool applied;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CompanyAvatar(fotoUrl: job['empresa_foto']?.toString(), size: 44),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job['titulo']?.toString() ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if ((job['empresa_nombre']?.toString() ?? '').isNotEmpty)
                        job['empresa_nombre'].toString(),
                      job['ubicacion']?.toString() ?? '—',
                      contractLabelT(context, job['tipo_contrato']?.toString()),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: c.inkMuted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    salaryLabelT(context, job),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: c.accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (applied)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(Icons.check_circle, size: 18, color: c.success),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(Icons.chevron_right, size: 20, color: c.inkFaint),
              ),
          ],
        ),
      ),
    );
  }
}

/// Detalle de una vacante: contenido + resumen lateral con CTA en escritorio;
/// una columna con CTA fijo al pie en móvil.
class OfferDetailPage extends StatefulWidget {
  const OfferDetailPage({super.key, required this.job});

  final Map<String, dynamic> job;

  @override
  State<OfferDetailPage> createState() => _OfferDetailPageState();
}

class _OfferDetailPageState extends State<OfferDetailPage> {
  late Future<Map<String, dynamic>?> _detailFuture;
  bool _isApplying = false;
  bool? _resolvedIsOpen;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  Future<Map<String, dynamic>?> _loadDetail() async {
    final puestoId = widget.job['puesto_id']?.toString() ?? '';
    final detail = await context.read<LookUpDataService>().fetchJobDetail(
      puestoId,
    );
    if (mounted) {
      final resolved = {...widget.job, if (detail != null) ...detail};
      setState(() => _resolvedIsOpen = _isJobOpen(resolved));
    }
    return detail;
  }

  bool _isJobOpen(Map<String, dynamic> job) =>
      (job['estado']?.toString() ?? 'abierto') == 'abierto';

  Future<void> _apply() async {
    final auth = context.read<AuthService>();
    final cuentaId = auth.cuentaId;
    final puestoId = widget.job['puesto_id']?.toString() ?? '';
    if (cuentaId == null || puestoId.isEmpty) return;

    setState(() => _isApplying = true);
    try {
      await context.read<LookUpDataService>().applyToJob(cuentaId, puestoId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('offers.sent'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: context.colors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<LookUpDataService>();
    final auth = context.watch<AuthService>();
    final puestoId = widget.job['puesto_id']?.toString() ?? '';
    final alreadyApplied = data.hasAppliedTo(puestoId);
    final isWide = MediaQuery.sizeOf(context).width >= 860;
    final isOpen = _resolvedIsOpen ?? _isJobOpen(widget.job);

    return Scaffold(
      appBar: AppBar(title: Text(context.t('offers.detail.title'))),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _detailFuture,
        builder: (context, snapshot) {
          final job = {
            ...widget.job,
            if (snapshot.data != null) ...snapshot.data!,
          };
          final isLoading =
              snapshot.connectionState == ConnectionState.waiting &&
              job['descripcion'] == null;
          final detailIsOpen = _isJobOpen(job);

          final summary = _SummaryPanel(
            job: job,
            isOpen: detailIsOpen,
            alreadyApplied: alreadyApplied,
            isApplying: _isApplying,
            canApply: auth.cuentaId != null,
            onApply: _apply,
            showCta: isWide,
          );
          final content = _MainContent(job: job, isLoading: isLoading);

          if (isWide) {
            return PageContainer(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: content),
                    const SizedBox(width: 20),
                    SizedBox(width: 320, child: summary),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              children: [summary, const SizedBox(height: 16), content],
            ),
          );
        },
      ),
      bottomNavigationBar: isWide
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  border: Border(top: BorderSide(color: context.colors.border)),
                ),
                child: ApplyButton(
                  alreadyApplied: alreadyApplied,
                  isApplying: _isApplying,
                  canApply: auth.cuentaId != null,
                  isOpen: isOpen,
                  onApply: _apply,
                ),
              ),
            ),
    );
  }
}

class _MainContent extends StatelessWidget {
  const _MainContent({required this.job, required this.isLoading});

  final Map<String, dynamic> job;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final requisitos = asMapList(job['requisitos']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CompanyAvatar(fotoUrl: job['empresa_foto']?.toString(), size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job['titulo']?.toString() ?? '—',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if ((job['empresa_nombre']?.toString() ?? '').isNotEmpty)
                        job['empresa_nombre'].toString(),
                      job['ubicacion']?.toString() ?? '—',
                      '${context.t('offers.published')} ${formatDate(job['fecha_publicacion'])}',
                    ].join(' · '),
                    style: TextStyle(color: c.inkMuted, fontSize: 13.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SectionHeader(title: context.t('offers.description')),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else
          Text(
            job['descripcion']?.toString() ?? '—',
            style: TextStyle(color: c.ink, height: 1.55, fontSize: 14.5),
          ),
        if (requisitos.isNotEmpty) ...[
          const SizedBox(height: 22),
          SectionHeader(title: context.t('offers.requirements')),
          ...requisitos.map((req) {
            final obligatorio = req['es_obligatorio'] == true;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    obligatorio
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    size: 19,
                    color: obligatorio ? c.brand : c.inkFaint,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      req['descripcion']?.toString() ?? '',
                      style: TextStyle(color: c.ink, height: 1.4, fontSize: 14),
                    ),
                  ),
                  if (!obligatorio)
                    Text(
                      context.t('offers.desirable'),
                      style: TextStyle(
                        color: c.inkFaint,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.job,
    required this.isOpen,
    required this.alreadyApplied,
    required this.isApplying,
    required this.canApply,
    required this.onApply,
    required this.showCta,
  });

  final Map<String, dynamic> job;
  final bool isOpen;
  final bool alreadyApplied;
  final bool isApplying;
  final bool canApply;
  final VoidCallback onApply;
  final bool showCta;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final empresaId = job['empresa_id']?.toString();

    Widget row(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c.inkFaint),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: c.inkFaint)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.t('offers.summary'),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: c.ink,
                  ),
                ),
              ),
              StatusChip(label: isOpen ? 'abierto' : 'cerrado', compact: true),
            ],
          ),
          const SizedBox(height: 16),
          row(
            Icons.payments_outlined,
            context.t('offers.salary'),
            salaryLabelT(context, job),
          ),
          row(
            Icons.badge_outlined,
            context.t('offers.contract'),
            contractLabelT(context, job['tipo_contrato']?.toString()),
          ),
          row(
            Icons.location_on_outlined,
            context.t('offers.location'),
            job['ubicacion']?.toString() ?? '—',
          ),
          if (empresaId != null && empresaId.isNotEmpty) ...[
            const SizedBox(height: 2),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CompanyScreen(empresaId: empresaId),
                ),
              ),
              icon: const Icon(Icons.business_outlined, size: 18),
              label: Text(context.t('offers.view_company')),
            ),
          ],
          if (showCta) ...[
            const SizedBox(height: 10),
            ApplyButton(
              alreadyApplied: alreadyApplied,
              isApplying: isApplying,
              canApply: canApply,
              isOpen: isOpen,
              onApply: onApply,
            ),
          ],
        ],
      ),
    );
  }
}

class ApplyButton extends StatelessWidget {
  const ApplyButton({
    super.key,
    required this.alreadyApplied,
    required this.isApplying,
    required this.canApply,
    required this.isOpen,
    required this.onApply,
  });

  final bool alreadyApplied;
  final bool isApplying;
  final bool canApply;
  final bool isOpen;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    if (alreadyApplied) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: Icon(Icons.check_circle, color: context.colors.success),
        label: Text(context.t('offers.applied.long')),
      );
    }
    if (!isOpen) {
      return OutlinedButton(
        onPressed: null,
        child: Text(context.t('offers.closed')),
      );
    }
    return ElevatedButton.icon(
      onPressed: isApplying || !canApply ? null : onApply,
      icon: isApplying
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.send_rounded, size: 18),
      label: Text(
        isApplying ? context.t('offers.applying') : context.t('offers.apply'),
      ),
    );
  }
}

class _CompanyRow extends StatelessWidget {
  const _CompanyRow({required this.empresa, required this.onTap});

  final Map<String, dynamic> empresa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            CompanyAvatar(fotoUrl: empresa['foto_url']?.toString(), size: 42),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    empresa['nombre']?.toString() ?? '?',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                  if ((empresa['ciudad']?.toString() ?? '').isNotEmpty)
                    Text(
                      empresa['ciudad'].toString(),
                      style: TextStyle(fontSize: 12.5, color: c.inkMuted),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: c.inkFaint),
          ],
        ),
      ),
    );
  }
}

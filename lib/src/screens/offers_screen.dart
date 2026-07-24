import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/screens/company_screen.dart';
import 'package:lookup_user/src/services/auth_service.dart';
import 'package:lookup_user/src/services/data_service.dart';
import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/theme.dart';
import 'package:lookup_user/src/utils/formatters.dart';
import 'package:lookup_user/src/widgets/common.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({
    super.key,
    this.onClearSearch,
    this.mobileSearchMode = false,
  });

  final VoidCallback? onClearSearch;
  final bool mobileSearchMode;

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final TextEditingController _mobileSearchController = TextEditingController();
  List<Map<String, dynamic>> _companies = [];
  int _searchStamp = 0;
  String _companyQuery = '';
  String _contractFilter = 'todos';
  bool _isSearchingCompanies = false;
  String? _companySearchError;
  bool _mobileQueryInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.mobileSearchMode && !_mobileQueryInitialized) {
      _mobileSearchController.text = context
          .read<LookUpDataService>()
          .searchQuery;
      _mobileQueryInitialized = true;
    }
  }

  @override
  void dispose() {
    _mobileSearchController.dispose();
    super.dispose();
  }

  void _updateMobileSearch(String value) {
    context.read<LookUpDataService>().setSearchQuery(value);
  }

  void _clearSearch() {
    _mobileSearchController.clear();
    (widget.onClearSearch ??
        () => context.read<LookUpDataService>().setSearchQuery(''))();
    setState(() {});
  }

  Future<void> _searchCompanies(String value) async {
    final stamp = ++_searchStamp;
    if (value.trim().length < 2) {
      if (_companies.isNotEmpty ||
          _isSearchingCompanies ||
          _companySearchError != null) {
        setState(() {
          _companies = [];
          _isSearchingCompanies = false;
          _companySearchError = null;
        });
      }
      return;
    }
    setState(() {
      _companies = [];
      _isSearchingCompanies = true;
      _companySearchError = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted || stamp != _searchStamp) return;
    try {
      final results = await context.read<LookUpDataService>().searchCompanies(
        value,
      );
      if (!mounted || stamp != _searchStamp) return;
      setState(() => _companies = results);
    } catch (error) {
      if (!mounted || stamp != _searchStamp) return;
      setState(() => _companySearchError = error.toString());
    } finally {
      if (mounted && stamp == _searchStamp) {
        setState(() => _isSearchingCompanies = false);
      }
    }
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
      final searchable = normalizeSearchText(
        '${job['titulo']} ${job['descripcion']} ${job['ubicacion']} '
        '${job['empresa_nombre'] ?? ''}',
      );
      final contract = job['tipo_contrato']?.toString() ?? '';
      return searchable.contains(normalizedQuery) &&
          (_contractFilter == 'todos' || contract == _contractFilter);
    }).toList();
    const contractFilters = [
      'todos',
      'tiempo_completo',
      'medio_tiempo',
      'practicas',
      'temporal',
    ];

    return RefreshIndicator(
      onRefresh: () {
        final accountId = context.read<AuthService>().cuentaId;
        return accountId == null
            ? context.read<LookUpDataService>().fetchJobs()
            : context.read<LookUpDataService>().refresh(accountId);
      },
      child: ViewportScrollPage(
        maxWidth: 980,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (data.error != null) ...[
              ErrorBanner(
                message: data.error!,
                actionLabel: context.t('common.retry'),
                onAction: () {
                  final accountId = context.read<AuthService>().cuentaId;
                  if (accountId != null) {
                    context.read<LookUpDataService>().refresh(accountId);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
            Text(
              context.t(
                widget.mobileSearchMode ? 'nav.search' : 'offers.title',
              ),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (!widget.mobileSearchMode) ...[
              const SizedBox(height: 3),
              Text(
                context
                    .t('offers.subtitle')
                    .replaceAll('{count}', '${data.jobs.length}'),
                style: TextStyle(color: c.inkMuted, fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: contractFilters.map((filter) {
                    final label = filter == 'todos'
                        ? context.t('offers.filter.all')
                        : contractLabelT(context, filter);
                    return Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ChoiceChip(
                        key: Key('offers-filter-$filter'),
                        label: Text(label),
                        selected: _contractFilter == filter,
                        selectedColor: const Color(0xFF2C3CA6),
                        backgroundColor: c.surface,
                        labelStyle: TextStyle(
                          color: _contractFilter == filter
                              ? Colors.white
                              : c.inkMuted,
                        ),
                        side: BorderSide(
                          color: _contractFilter == filter
                              ? Colors.transparent
                              : c.border,
                        ),
                        showCheckmark: false,
                        onSelected: (_) =>
                            setState(() => _contractFilter = filter),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            if (widget.mobileSearchMode) ...[
              const SizedBox(height: 14),
              TextField(
                key: const Key('mobile-search-field'),
                controller: _mobileSearchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _updateMobileSearch,
                decoration: InputDecoration(
                  hintText: context.t('search.hint'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: context.t('search.clear'),
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: _clearSearch,
                        ),
                ),
              ),
            ],
            if (query.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${context.t('search.results_for')} "$query"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.inkMuted, fontSize: 12.5),
                    ),
                  ),
                  if (!widget.mobileSearchMode)
                    TextButton.icon(
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.close, size: 16),
                      label: Text(context.t('search.clear')),
                    ),
                ],
              ),
            ],
            if (query.trim().length >= 2 &&
                (_companies.isNotEmpty ||
                    _isSearchingCompanies ||
                    _companySearchError != null)) ...[
              const SizedBox(height: 12),
              SectionHeader(title: context.t('search.companies')),
              if (_isSearchingCompanies)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (_companySearchError != null)
                ErrorBanner(
                  message: _companySearchError!,
                  actionLabel: context.t('common.retry'),
                  onAction: () => _searchCompanies(query),
                ),
              ..._companies.map(
                (company) => _CompanyRow(
                  company: company,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CompanyScreen(
                        empresaId: company['cuenta_id'].toString(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SectionHeader(title: context.t('search.vacancies')),
            ],
            const SizedBox(height: 8),
            if (data.isLoading && data.jobs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filtered.isEmpty)
              EmptyState(
                icon: Icons.work_off_outlined,
                title: query.isEmpty
                    ? context.t('offers.empty.title')
                    : '"$query"',
                message: query.isEmpty
                    ? context.t('offers.empty.msg')
                    : context.t('offers.no_results.msg'),
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

class JobRow extends StatelessWidget {
  const JobRow({
    super.key,
    required this.job,
    required this.applied,
    required this.onTap,
    this.dense = false,
  });

  final Map<String, dynamic> job;
  final bool applied;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final companyName = job['empresa_nombre']?.toString().trim() ?? '';
    final photo = job['empresa_foto']?.toString().trim() ?? '';
    final published = relativeDateT(
      context,
      job['fecha_publicacion']?.toString(),
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: dense ? 11 : 13),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (photo.isNotEmpty)
              CompanyAvatar(fotoUrl: photo, size: dense ? 36 : 40)
            else
              InitialsAvatar(
                name: companyName.isEmpty
                    ? job['titulo']?.toString() ?? '?'
                    : companyName,
                size: dense ? 36 : 40,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job['titulo']?.toString() ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: dense ? 13 : 14,
                      fontWeight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (companyName.isNotEmpty) companyName,
                      job['ubicacion']?.toString() ?? '—',
                      contractLabelT(context, job['tipo_contrato']?.toString()),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: dense ? 10.5 : 11.5,
                      color: c.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: dense ? 145 : 190),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (applied)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 7, color: c.success),
                        const SizedBox(width: 4),
                        Text(
                          context.t('offers.applied'),
                          style: TextStyle(
                            color: c.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  Text(
                    salaryLabelT(context, job),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: dense ? 11 : 12,
                      fontWeight: FontWeight.w700,
                      color: c.accent,
                    ),
                  ),
                  if (published.isNotEmpty)
                    Text(
                      published,
                      style: TextStyle(color: c.inkFaint, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

  void _retryDetail() {
    setState(() {
      _resolvedIsOpen = null;
      _detailFuture = _loadDetail();
    });
  }

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
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
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
      appBar: AppBar(
        toolbarHeight: 44,
        titleSpacing: 0,
        title: Text(
          context.t('offers.back'),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
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
          final content = _MainContent(job: job, isLoading: isLoading);
          final summary = _SummaryPanel(
            job: job,
            isOpen: detailIsOpen,
            alreadyApplied: alreadyApplied,
            isApplying: _isApplying,
            canApply: auth.cuentaId != null,
            onApply: _apply,
            showCta: isWide,
            desktop: isWide,
          );

          return ViewportScrollPage(
            maxWidth: 980,
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (snapshot.hasError) ...[
                  ErrorBanner(message: snapshot.error.toString()),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _retryDetail,
                      icon: const Icon(Icons.refresh, size: 17),
                      label: Text(context.t('common.retry')),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                _JobHero(job: job, isOpen: detailIsOpen),
                const SizedBox(height: 18),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: content),
                      const SizedBox(width: 24),
                      SizedBox(width: 300, child: summary),
                    ],
                  )
                else ...[
                  summary,
                  const SizedBox(height: 20),
                  content,
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: isWide
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 9, 18, 11),
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

class _JobHero extends StatelessWidget {
  const _JobHero({required this.job, required this.isOpen});

  final Map<String, dynamic> job;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final company = job['empresa_nombre']?.toString() ?? '';
    return BrandGradientPanel(
      height: 112,
      showBottomLeftRing: false,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: InitialsAvatar(
              name: company.isEmpty
                  ? job['titulo']?.toString() ?? '?'
                  : company,
              size: 38,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job['titulo']?.toString() ?? '—',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                if (company.isNotEmpty)
                  Text(
                    company,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOpen ? Icons.circle : Icons.lock_outline,
                  size: 10,
                  color: Colors.white,
                ),
                const SizedBox(width: 5),
                Text(
                  context.t(isOpen ? 'estado.abierto' : 'estado.cerrado'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final requirements = asMapList(job['requisitos']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: context.t('offers.description')),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(18),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Text(
            job['descripcion']?.toString() ?? '—',
            style: TextStyle(color: c.ink, height: 1.55, fontSize: 13),
          ),
        if (requirements.isNotEmpty) ...[
          const SizedBox(height: 22),
          SectionHeader(title: context.t('offers.requirements')),
          ...requirements.map((requirement) {
            final required = requirement['es_obligatorio'] == true;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: required ? c.brand : c.inkFaint,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      requirement['descripcion']?.toString() ?? '',
                      style: TextStyle(
                        color: c.ink,
                        height: 1.4,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  if (!required)
                    Text(
                      context.t('offers.desirable'),
                      style: TextStyle(
                        color: c.inkFaint,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
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
    required this.desktop,
  });

  final Map<String, dynamic> job;
  final bool isOpen;
  final bool alreadyApplied;
  final bool isApplying;
  final bool canApply;
  final VoidCallback onApply;
  final bool showCta;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final companyId = job['empresa_id']?.toString();
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: c.inkFaint, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: c.ink,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: EdgeInsets.only(
        left: desktop ? 20 : 16,
        right: desktop ? 0 : 16,
        top: desktop ? 0 : 15,
        bottom: desktop ? 0 : 15,
      ),
      decoration: BoxDecoration(
        color: desktop ? Colors.transparent : c.surfaceAlt,
        border: desktop
            ? Border(left: BorderSide(color: c.border))
            : Border.all(color: c.border),
        borderRadius: desktop ? null : BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.t('offers.summary').toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: c.inkFaint),
          ),
          const SizedBox(height: 12),
          Text(
            salaryLabelT(context, job),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: c.accent, fontSize: 18),
          ),
          const SizedBox(height: 14),
          row(
            context.t('offers.contract'),
            contractLabelT(context, job['tipo_contrato']?.toString()),
          ),
          row(
            context.t('offers.location'),
            job['ubicacion']?.toString() ?? '—',
          ),
          row(
            context.t('offers.published.short'),
            relativeDateT(context, job['fecha_publicacion']?.toString()),
          ),
          if (showCta) ...[
            const SizedBox(height: 8),
            ApplyButton(
              alreadyApplied: alreadyApplied,
              isApplying: isApplying,
              canApply: canApply,
              isOpen: isOpen,
              onApply: onApply,
            ),
          ],
          if (companyId != null && companyId.isNotEmpty) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CompanyScreen(empresaId: companyId),
                ),
              ),
              icon: const Icon(Icons.business_outlined, size: 16),
              label: Text(context.t('offers.view_company')),
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
    return FilledButton.icon(
      onPressed: isApplying || !canApply ? null : onApply,
      icon: isApplying
          ? const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.send_rounded, size: 16),
      label: Text(
        isApplying ? context.t('offers.applying') : context.t('offers.apply'),
      ),
    );
  }
}

class _CompanyRow extends StatelessWidget {
  const _CompanyRow({required this.company, required this.onTap});

  final Map<String, dynamic> company;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final name = company['nombre']?.toString() ?? '?';
    final photo = company['foto_url']?.toString().trim() ?? '';
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            if (photo.isEmpty)
              InitialsAvatar(name: name, size: 38)
            else
              CompanyAvatar(fotoUrl: photo, size: 38),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                  if ((company['ciudad']?.toString() ?? '').isNotEmpty)
                    Text(
                      company['ciudad'].toString(),
                      style: TextStyle(fontSize: 12, color: c.inkMuted),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: c.inkFaint),
          ],
        ),
      ),
    );
  }
}

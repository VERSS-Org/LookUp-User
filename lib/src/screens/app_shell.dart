import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/screens/applications_screen.dart';
import 'package:lookup_user/src/screens/company_screen.dart';
import 'package:lookup_user/src/screens/home_screen.dart';
import 'package:lookup_user/src/screens/messages_screen.dart';
import 'package:lookup_user/src/screens/metrics_screen.dart';
import 'package:lookup_user/src/screens/notifications_screen.dart';
import 'package:lookup_user/src/screens/offers_screen.dart';
import 'package:lookup_user/src/screens/profile_screen.dart';
import 'package:lookup_user/src/services/auth_service.dart';
import 'package:lookup_user/src/services/data_service.dart';
import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/services/theme_controller.dart';
import 'package:lookup_user/src/theme.dart';
import 'package:lookup_user/src/utils/formatters.dart';
import 'package:lookup_user/src/widgets/common.dart';

/// Shell principal del postulante.
///
/// En web ancha todo vive bajo el navbar superior: las secciones cambian el
/// contenido y las páginas de detalle se apilan en un Navigator interno, así
/// nunca se siente que se abre "otra ventana".
/// En móvil: appbar (mensajes + notificaciones | logo | perfil) y barra
/// inferior con las 4 secciones.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // 0..3: secciones principales · 4: mensajes · 6: perfil · 7: búsqueda móvil
  int _index = 0;
  int _primaryIndex = 0;
  String? _requestedConversationId;
  final SearchController _searchController = SearchController();
  GlobalKey<NavigatorState> _contentNavigatorKey = GlobalKey<NavigatorState>();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _select(int index) {
    final changed = _index != index;
    setState(() {
      _index = index;
      if ((index >= 0 && index <= 3) || index == 7) {
        _primaryIndex = index;
      }
      if (changed) {
        _contentNavigatorKey = GlobalKey<NavigatorState>();
      }
    });
    if (!changed) {
      _contentNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
    if (index == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<LookUpDataService>().markProcessesSeen();
      });
    }
    if (index == 5) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<LookUpDataService>().markNotificationsSeen();
      });
    }
  }

  void _setSearchQuery(String value) {
    context.read<LookUpDataService>().setSearchQuery(value);
  }

  void _showSearchResults(String value) {
    final query = value.trim();
    _searchController.text = query;
    _setSearchQuery(query);
    if (_searchController.isOpen) {
      _searchController.closeView(query);
    }
    _select(1);
  }

  void _clearSearch() {
    _searchController.clear();
    _setSearchQuery('');
  }

  void _openJobFromSearch(Map<String, dynamic> job) {
    final query = _searchController.text.trim();
    _setSearchQuery(query);
    if (_searchController.isOpen) {
      _searchController.closeView(query);
    }
    _openSearchDestination(OfferDetailPage(job: job));
  }

  void _openCompanyFromSearch(Map<String, dynamic> company) {
    final query = _searchController.text.trim();
    _setSearchQuery(query);
    if (_searchController.isOpen) {
      _searchController.closeView(query);
    }
    final companyId = company['cuenta_id']?.toString() ?? '';
    if (companyId.isEmpty) return;
    _openSearchDestination(CompanyScreen(empresaId: companyId));
  }

  void _openSearchDestination(Widget page) {
    final isWide = MediaQuery.sizeOf(context).width >= 960;
    if (isWide) {
      _select(1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _contentNavigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => page),
        );
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
      });
    }
  }

  void _openMessages() {
    _requestedConversationId = null;
    final isWide = MediaQuery.sizeOf(context).width >= 960;
    if (isWide) {
      _select(4);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MessagesScreen()),
      );
    }
  }

  void _openConversation(String postulacionId) {
    _requestedConversationId = postulacionId;
    final isWide = MediaQuery.sizeOf(context).width >= 960;
    if (isWide) {
      _select(4);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessagesScreen(initialPostulacionId: postulacionId),
      ),
    );
  }

  void _openNotifications() {
    final isWide = MediaQuery.sizeOf(context).width >= 960;
    if (isWide) {
      context.read<LookUpDataService>().markNotificationsSeen();
      final size = MediaQuery.sizeOf(context);
      showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.12),
        builder: (dialogContext) => Dialog(
          alignment: Alignment.topRight,
          insetPadding: const EdgeInsets.only(top: 68, right: 68, left: 20),
          backgroundColor: Colors.transparent,
          elevation: 8,
          child: SizedBox(
            key: const Key('notifications-popover'),
            width: 420,
            height: (size.height - 92).clamp(320, 560).toDouble(),
            child: const NotificationsScreen(popup: true),
          ),
        ),
      );
    } else {
      context.read<LookUpDataService>().markNotificationsSeen();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
    }
  }

  void _openProfile() {
    final isWide = MediaQuery.sizeOf(context).width >= 960;
    if (isWide) {
      _select(6);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    }
  }

  Widget _pageFor(int index) {
    switch (index) {
      case 0:
        return HomeScreen(
          onOpenMessages: _openMessages,
          onOpenNotifications: _openNotifications,
        );
      case 1:
        return OffersScreen(onClearSearch: _clearSearch);
      case 2:
        return ApplicationsScreen(onOpenConversation: _openConversation);
      case 3:
        return const MetricsScreen();
      case 4:
        return MessagesScreen(
          key: ValueKey(_requestedConversationId),
          embedded: true,
          initialPostulacionId: _requestedConversationId,
        );
      case 7:
        return OffersScreen(
          mobileSearchMode: true,
          onClearSearch: _clearSearch,
        );
      default:
        return const ProfileScreen(embedded: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<LookUpDataService>();
    final destinations = [
      (
        icon: Icons.home_outlined,
        selected: Icons.home,
        label: context.t('nav.home'),
      ),
      (
        icon: Icons.work_outline,
        selected: Icons.work,
        label: context.t('nav.offers'),
      ),
      (
        icon: Icons.fact_check_outlined,
        selected: Icons.fact_check,
        label: context.t('nav.processes'),
      ),
      (
        icon: Icons.insights_outlined,
        selected: Icons.insights,
        label: context.t('nav.metrics'),
      ),
    ];
    final isWide = MediaQuery.sizeOf(context).width >= 960;
    final effectiveWideIndex = _index == 7 ? 1 : _index;
    final c = context.colors;

    if (isWide) {
      return Scaffold(
        body: Column(
          children: [
            _TopNavBar(
              index: effectiveWideIndex,
              destinations: destinations,
              unread: data.unreadMessages,
              processAlerts: data.processAlerts,
              notifications: data.unseenNotifications,
              onSelect: _select,
              onOpenMessages: _openMessages,
              onOpenNotifications: _openNotifications,
              onOpenProfile: _openProfile,
              searchController: _searchController,
              onSearchChanged: _setSearchQuery,
              onSearchSubmitted: _showSearchResults,
              onClearSearch: _clearSearch,
              onOpenJob: _openJobFromSearch,
              onOpenCompany: _openCompanyFromSearch,
            ),
            // Navigator interno: los detalles se apilan aquí debajo del
            // navbar, en lugar de tapar toda la pantalla.
            Expanded(
              child: _SectionSwitcher(
                transitionKey: effectiveWideIndex,
                child: Navigator(
                  key: _contentNavigatorKey,
                  onGenerateRoute: (settings) => MaterialPageRoute(
                    settings: settings,
                    builder: (_) => _pageFor(effectiveWideIndex),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        leadingWidth: 52,
        leading: BadgedIconButton(
          icon: Icons.chat_outlined,
          count: data.unreadMessages,
          tooltip: context.t('nav.messages'),
          onPressed: _openMessages,
        ),
        title: const BrandMark(size: 32),
        actions: [
          BadgedIconButton(
            icon: Icons.notifications_outlined,
            count: data.unseenNotifications,
            tooltip: context.t('notif.title'),
            onPressed: _openNotifications,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 2, right: 10),
            child: Builder(
              builder: (context) => InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Scaffold.of(context).openEndDrawer(),
                child: ProfileAvatar(
                  fotoUrl: context
                      .watch<AuthService>()
                      .profile?['foto_url']
                      ?.toString(),
                  radius: 17,
                  name:
                      context
                          .watch<AuthService>()
                          .profile?['nombre_completo']
                          ?.toString() ??
                      context.t('common.applicant'),
                ),
              ),
            ),
          ),
        ],
      ),
      endDrawer: const ProfileDrawer(),
      body: _SectionSwitcher(
        transitionKey: _isPrimarySection(_index) ? _index : _primaryIndex,
        child: _pageFor(_isPrimarySection(_index) ? _index : _primaryIndex),
      ),
      bottomNavigationBar: Container(
        key: const Key('mobile-bottom-navigation'),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: NavigationBar(
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          selectedIndex: _mobileDestinationIndex(
            _isPrimarySection(_index) ? _index : _primaryIndex,
          ),
          onDestinationSelected: (index) {
            _select(const <int>[0, 7, 1, 2, 3][index]);
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: context.t('nav.home'),
            ),
            NavigationDestination(
              key: const Key('mobile-search-destination'),
              icon: const Icon(Icons.search),
              selectedIcon: const Icon(Icons.manage_search),
              label: context.t('nav.search'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.work_outline),
              selectedIcon: const Icon(Icons.work),
              label: context.t('nav.offers'),
            ),
            NavigationDestination(
              icon: data.processAlerts > 0
                  ? Badge.count(
                      count: data.processAlerts,
                      child: const Icon(Icons.fact_check_outlined),
                    )
                  : const Icon(Icons.fact_check_outlined),
              selectedIcon: const Icon(Icons.fact_check),
              label: context.t('nav.processes'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: const Icon(Icons.insights),
              label: context.t('nav.metrics'),
            ),
          ],
        ),
      ),
    );
  }

  bool _isPrimarySection(int index) => (index >= 0 && index <= 3) || index == 7;

  int _mobileDestinationIndex(int sectionIndex) {
    return switch (sectionIndex) {
      0 => 0,
      7 => 1,
      1 => 2,
      2 => 3,
      3 => 4,
      _ => 0,
    };
  }
}

/// Cambio de sección breve y consistente, sin desplazar el contenido ni
/// introducir efectos decorativos que compitan con la interfaz.
class _SectionSwitcher extends StatelessWidget {
  const _SectionSwitcher({required this.transitionKey, required this.child});

  final Object transitionKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 140),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.01, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(transitionKey), child: child),
    );
  }
}

/// Navbar superior para pantallas anchas.
class _TopNavBar extends StatelessWidget {
  const _TopNavBar({
    required this.index,
    required this.destinations,
    required this.unread,
    required this.processAlerts,
    required this.notifications,
    required this.onSelect,
    required this.onOpenMessages,
    required this.onOpenNotifications,
    required this.onOpenProfile,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onClearSearch,
    required this.onOpenJob,
    required this.onOpenCompany,
  });

  final int index;
  final List<({IconData icon, IconData selected, String label})> destinations;
  final int unread;
  final int processAlerts;
  final int notifications;
  final ValueChanged<int> onSelect;
  final VoidCallback onOpenMessages;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenProfile;
  final SearchController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onClearSearch;
  final ValueChanged<Map<String, dynamic>> onOpenJob;
  final ValueChanged<Map<String, dynamic>> onOpenCompany;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = context.watch<AuthService>();
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final compactNav = viewportWidth < 1240;
    final searchWidth = viewportWidth >= 1600
        ? 540.0
        : viewportWidth >= 1360
        ? 480.0
        : viewportWidth >= 1180
        ? 380.0
        : 280.0;
    final nombre =
        auth.profile?['nombre_completo']?.toString() ??
        context.t('common.applicant');

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: compactNav ? 14 : 18),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onSelect(0),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: BrandMark(size: 38),
            ),
          ),
          SizedBox(width: compactNav ? 8 : 16),
          for (var i = 0; i < destinations.length; i++)
            _NavLink(
              label: destinations[i].label,
              selected: index == i,
              badge: i == 2 ? processAlerts : 0,
              compact: compactNav,
              onTap: () => onSelect(i),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: searchWidth,
                child: _GlobalSearch(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  onSubmitted: onSearchSubmitted,
                  onClear: onClearSearch,
                  onOpenJob: onOpenJob,
                  onOpenCompany: onOpenCompany,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          BadgedIconButton(
            icon: Icons.chat_outlined,
            count: unread,
            tooltip: context.t('nav.messages'),
            onPressed: onOpenMessages,
          ),
          BadgedIconButton(
            icon: Icons.notifications_outlined,
            count: notifications,
            tooltip: context.t('notif.title'),
            onPressed: onOpenNotifications,
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: nombre,
            offset: const Offset(0, 46),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'perfil',
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 19),
                    const SizedBox(width: 10),
                    Text(context.tr('nav.my_profile')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 19, color: c.danger),
                    const SizedBox(width: 10),
                    Text(
                      context.tr('nav.logout'),
                      style: TextStyle(color: c.danger),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'perfil') {
                onOpenProfile();
              } else if (value == 'logout') {
                final data = context.read<LookUpDataService>();
                data.clear();
                await context.read<AuthService>().logout();
              }
            },
            child: ProfileAvatar(
              fotoUrl: auth.profile?['foto_url']?.toString(),
              radius: 17,
              name: nombre,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlobalSearch extends StatefulWidget {
  const _GlobalSearch({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onOpenJob,
    required this.onOpenCompany,
  });

  final SearchController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final ValueChanged<Map<String, dynamic>> onOpenJob;
  final ValueChanged<Map<String, dynamic>> onOpenCompany;

  @override
  State<_GlobalSearch> createState() => _GlobalSearchState();
}

class _GlobalSearchState extends State<_GlobalSearch> {
  int _requestId = 0;
  Iterable<Widget> _lastOptions = const <Widget>[];

  Future<Iterable<Widget>> _suggestions(
    BuildContext context,
    SearchController controller,
  ) async {
    final query = controller.text.trim();
    final requestId = ++_requestId;
    final data = context.read<LookUpDataService>();
    final vacanciesLabel = context.tr('search.vacancies');
    final companiesLabel = context.tr('search.companies');
    final emptyTitle = context.tr('search.empty.title');
    final emptyMessage = context.tr('search.empty.msg');
    final allResultsLabel = context.tr('search.all_results');
    if (query.isEmpty) {
      _lastOptions = [
        _SearchPrompt(
          icon: Icons.manage_search_outlined,
          title: context.tr('search.start.title'),
          message: context.tr('search.start.msg'),
        ),
      ];
      return _lastOptions;
    }

    await Future<void>.delayed(const Duration(milliseconds: 240));
    if (requestId != _requestId) return _lastOptions;

    final normalizedQuery = normalizeSearchText(query);
    final jobs = data.jobs
        .where((job) {
          final searchable = normalizeSearchText(
            '${job['titulo']} ${job['descripcion']} ${job['ubicacion']} '
            '${job['empresa_nombre'] ?? ''}',
          );
          return searchable.contains(normalizedQuery);
        })
        .take(4)
        .toList();
    final companies = query.length >= 2
        ? await data.searchCompanies(query)
        : <Map<String, dynamic>>[];
    if (requestId != _requestId) return _lastOptions;

    final options = <Widget>[];
    if (jobs.isNotEmpty) {
      options.add(_SearchSectionLabel(vacanciesLabel));
      options.addAll(
        jobs.map(
          (job) => ListTile(
            leading: CompanyAvatar(
              fotoUrl: job['empresa_foto']?.toString(),
              size: 38,
            ),
            title: Text(
              job['titulo']?.toString() ?? '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              [
                job['empresa_nombre']?.toString() ?? '',
                job['ubicacion']?.toString() ?? '',
              ].where((part) => part.isNotEmpty).join(' \u00b7 '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => widget.onOpenJob(job),
          ),
        ),
      );
    }
    if (companies.isNotEmpty) {
      options.add(_SearchSectionLabel(companiesLabel));
      options.addAll(
        companies
            .take(4)
            .map(
              (company) => ListTile(
                leading: CompanyAvatar(
                  fotoUrl: company['foto_url']?.toString(),
                  size: 38,
                ),
                title: Text(
                  company['nombre']?.toString() ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  company['ciudad']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => widget.onOpenCompany(company),
              ),
            ),
      );
    }
    if (options.isEmpty) {
      options.add(
        _SearchPrompt(
          icon: Icons.search_off_outlined,
          title: emptyTitle,
          message: emptyMessage,
        ),
      );
    }
    options.add(const Divider(height: 1));
    options.add(
      ListTile(
        leading: const Icon(Icons.arrow_forward),
        title: Text(allResultsLabel),
        onTap: () => widget.onSubmitted(query),
      ),
    );
    _lastOptions = options;
    return options;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hint = context.t('search.hint');

    return SearchAnchor(
      searchController: widget.controller,
      isFullScreen: false,
      viewHintText: hint,
      viewBackgroundColor: c.surface,
      viewSurfaceTintColor: Colors.transparent,
      viewElevation: 0,
      viewSide: BorderSide(color: c.border),
      viewShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      viewConstraints: const BoxConstraints(
        minWidth: 420,
        maxWidth: 520,
        maxHeight: 580,
      ),
      dividerColor: c.border,
      viewOnChanged: widget.onChanged,
      viewOnSubmitted: widget.onSubmitted,
      viewTrailing: [
        IconButton(
          tooltip: context.t('search.clear'),
          icon: const Icon(Icons.close),
          onPressed: () {
            widget.controller.clear();
            widget.onClear();
          },
        ),
      ],
      suggestionsBuilder: _suggestions,
      builder: (context, controller) {
        return SearchBar(
          controller: controller,
          hintText: hint,
          leading: Icon(Icons.search, size: 20, color: c.inkFaint),
          constraints: const BoxConstraints(minHeight: 40, maxHeight: 40),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12),
          ),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStatePropertyAll(c.surfaceAlt),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          side: WidgetStatePropertyAll(BorderSide(color: c.border)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          textStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 13.5, color: c.ink),
          ),
          hintStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 13, color: c.inkFaint),
          ),
          onTap: controller.openView,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
        );
      },
    );
  }
}

class _SearchSectionLabel extends StatelessWidget {
  const _SearchSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: context.colors.inkFaint,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30, color: c.inkFaint),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.inkMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final int badge;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 14),
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 3),
            Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 13.5 : 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? c.brand : c.inkMuted,
                  ),
                ),
                if (badge > 0) ...[
                  const SizedBox(width: 6),
                  Badge.count(count: badge),
                ],
              ],
            ),
            const SizedBox(height: 3),
            Container(
              height: 2.5,
              width: 26,
              decoration: BoxDecoration(
                color: selected ? c.brand : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icono con badge numérico (mensajes sin leer, notificaciones, etc.).
class BadgedIconButton extends StatelessWidget {
  const BadgedIconButton({
    super.key,
    required this.icon,
    required this.count,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final int count;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: count > 0
          ? Badge.count(count: count, child: Icon(icon))
          : Icon(icon),
    );
  }
}

/// Panel lateral de perfil en móvil: resumen, accesos y configuración rápida.
class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = context.watch<AuthService>();
    final themeController = context.watch<ThemeController>();
    final localeController = context.watch<LocaleController>();
    final profile = auth.profile ?? const <String, dynamic>{};
    final nombre =
        profile['nombre_completo']?.toString() ?? context.t('common.applicant');

    return Drawer(
      backgroundColor: c.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              child: Row(
                children: [
                  ProfileAvatar(
                    fotoUrl: profile['foto_url']?.toString(),
                    radius: 26,
                    name: nombre,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15.5,
                            color: c.ink,
                          ),
                        ),
                        Text(
                          profile['email']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: c.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: c.border, height: 1),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(context.t('nav.my_profile')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            Divider(color: c.border, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: Text(
                context.t('settings.title').toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: c.inkFaint,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('settings.theme'),
                    style: TextStyle(fontSize: 13, color: c.inkMuted),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: const Icon(Icons.light_mode_outlined, size: 17),
                        tooltip: context.t('settings.theme.light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: const Icon(Icons.dark_mode_outlined, size: 17),
                        tooltip: context.t('settings.theme.dark'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: const Icon(
                          Icons.brightness_auto_outlined,
                          size: 17,
                        ),
                        tooltip: context.t('settings.theme.system'),
                      ),
                    ],
                    selected: {themeController.mode},
                    onSelectionChanged: (selection) =>
                        themeController.setMode(selection.first),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.t('settings.language'),
                    style: TextStyle(fontSize: 13, color: c.inkMuted),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 'es', label: Text('Español')),
                      ButtonSegment(value: 'en', label: Text('English')),
                    ],
                    selected: {localeController.language},
                    onSelectionChanged: (selection) =>
                        localeController.setLanguage(selection.first),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Divider(color: c.border, height: 1),
            ListTile(
              leading: Icon(Icons.logout, color: c.danger),
              title: Text(
                context.t('nav.logout'),
                style: TextStyle(color: c.danger),
              ),
              onTap: () async {
                Navigator.pop(context);
                final data = context.read<LookUpDataService>();
                data.clear();
                await context.read<AuthService>().logout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

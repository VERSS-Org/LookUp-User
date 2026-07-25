import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/services/auth_service.dart';
import 'package:lookup_user/src/services/data_service.dart';
import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/services/theme_controller.dart';
import 'package:lookup_user/src/theme.dart';
import 'package:lookup_user/src/utils/formatters.dart';
import 'package:lookup_user/src/widgets/common.dart';
import 'package:lookup_user/src/widgets/photo_cropper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.embedded = false});

  final bool embedded;

  Map<String, dynamic> _profileDetails(Map<String, dynamic> profile) {
    final raw = profile['perfil'];
    return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  }

  Future<void> _saveDetails(
    BuildContext context,
    Map<String, dynamic> details,
  ) async {
    try {
      await context.read<AuthService>().updateProfile({'perfil': details});
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final themeController = context.watch<ThemeController>();
    final localeController = context.watch<LocaleController>();
    final c = context.colors;
    final profile = auth.profile ?? const <String, dynamic>{};
    final details = _profileDetails(profile);
    final name =
        profile['nombre_completo']?.toString().trim().isNotEmpty == true
        ? profile['nombre_completo'].toString().trim()
        : context.t('common.applicant');
    final about = details['descripcion']?.toString().trim() ?? '';

    final leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: context.t('profile.about'),
          actionLabel: context.t('common.edit'),
          onAction: () => _editAbout(context, details, about),
        ),
        Text(
          about.isEmpty ? context.t('profile.about.hint') : about,
          style: TextStyle(
            color: about.isEmpty ? c.inkFaint : c.ink,
            fontSize: 12.5,
            height: 1.55,
            fontStyle: about.isEmpty ? FontStyle.italic : null,
          ),
        ),
        const SizedBox(height: 20),
        _ProfileEntrySection(
          title: context.t('profile.experience'),
          icon: Icons.work_outline,
          entries: asMapList(details['experiencia']),
          titleKey: 'puesto',
          subtitleKeys: const ['organizacion', 'periodo'],
          bodyKey: 'descripcion',
          onAdd: () => _addEntry(
            context,
            details,
            'experiencia',
            context.tr('profile.add_experience'),
            [
              ('puesto', context.tr('profile.position'), true),
              ('organizacion', context.tr('profile.organization'), true),
              ('periodo', context.tr('profile.period'), false),
              ('descripcion', context.tr('profile.description'), false),
            ],
          ),
          onDelete: (index) =>
              _deleteEntry(context, details, 'experiencia', index),
        ),
        _ProfileEntrySection(
          title: context.t('profile.education'),
          icon: Icons.school_outlined,
          entries: asMapList(details['educacion']),
          titleKey: 'titulo',
          subtitleKeys: const ['institucion', 'periodo'],
          onAdd: () => _addEntry(
            context,
            details,
            'educacion',
            context.tr('profile.add_education'),
            [
              ('titulo', context.tr('profile.degree'), true),
              ('institucion', context.tr('profile.institution'), true),
              ('periodo', context.tr('profile.period'), false),
            ],
          ),
          onDelete: (index) =>
              _deleteEntry(context, details, 'educacion', index),
        ),
        _ProfileEntrySection(
          title: context.t('profile.certificates'),
          icon: Icons.verified_outlined,
          entries: asMapList(details['certificados']),
          titleKey: 'nombre',
          subtitleKeys: const ['anio'],
          onAdd: () => _addEntry(
            context,
            details,
            'certificados',
            context.tr('profile.add_certificate'),
            [
              ('nombre', context.tr('profile.cert_name'), true),
              ('anio', context.tr('profile.year'), false),
            ],
          ),
          onDelete: (index) =>
              _deleteEntry(context, details, 'certificados', index),
        ),
        _ProfileEntrySection(
          title: context.t('profile.extras'),
          icon: Icons.star_outline,
          entries: asMapList(details['extras']),
          titleKey: 'titulo',
          subtitleKeys: const [],
          bodyKey: 'descripcion',
          onAdd: () => _addEntry(
            context,
            details,
            'extras',
            context.tr('profile.add_extra'),
            [
              ('titulo', context.tr('profile.extra_title'), true),
              ('descripcion', context.tr('profile.description'), false),
            ],
          ),
          onDelete: (index) => _deleteEntry(context, details, 'extras', index),
        ),
      ],
    );

    final rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: context.t('profile.skills'),
          actionLabel: context.t('common.add'),
          onAction: () => _addSkill(context, details),
        ),
        _SkillsWrap(
          skills: List<dynamic>.from(
            (details['habilidades'] as List?) ?? const [],
          ),
          onDelete: (index) {
            final skills = List<dynamic>.from(
              (details['habilidades'] as List?) ?? const [],
            )..removeAt(index);
            _saveDetails(context, {...details, 'habilidades': skills});
          },
        ),
        const SizedBox(height: 20),
        _ProfileEntrySection(
          title: context.t('profile.languages'),
          icon: Icons.translate_outlined,
          entries: asMapList(details['idiomas']),
          titleKey: 'idioma',
          subtitleKeys: const ['nivel'],
          onAdd: () => _addEntry(
            context,
            details,
            'idiomas',
            context.tr('profile.add_language'),
            [
              ('idioma', context.tr('profile.language'), true),
              ('nivel', context.tr('profile.level'), false),
            ],
          ),
          onDelete: (index) => _deleteEntry(context, details, 'idiomas', index),
        ),
        SectionHeader(title: context.t('settings.privacy')),
        SwitchListTile.adaptive(
          key: const Key('profile-show-email-switch'),
          contentPadding: EdgeInsets.zero,
          title: Text(
            context.t('settings.privacy.email.title'),
            style: TextStyle(
              color: c.ink,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
          subtitle: Text(
            context.t('settings.privacy.email.subtitle'),
            style: TextStyle(color: c.inkMuted, fontSize: 12),
          ),
          value: details['mostrar_email'] != false,
          onChanged: (value) =>
              _saveDetails(context, {...details, 'mostrar_email': value}),
        ),
        const SizedBox(height: 17),
        SectionHeader(title: context.t('profile.preferences')),
        Text(
          context.t('settings.theme'),
          style: TextStyle(color: c.inkMuted, fontSize: 12),
        ),
        const SizedBox(height: 7),
        SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: ThemeMode.light,
              icon: const Icon(Icons.light_mode_outlined, size: 14),
              label: Text(context.t('settings.theme.light')),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: const Icon(Icons.dark_mode_outlined, size: 14),
              label: Text(context.t('settings.theme.dark')),
            ),
            ButtonSegment(
              value: ThemeMode.system,
              icon: const Icon(Icons.brightness_auto_outlined, size: 14),
              label: Text(context.t('settings.theme.system')),
            ),
          ],
          selected: {themeController.mode},
          onSelectionChanged: (selection) =>
              themeController.setMode(selection.first),
        ),
        const SizedBox(height: 13),
        Text(
          context.t('settings.language'),
          style: TextStyle(color: c.inkMuted, fontSize: 12),
        ),
        const SizedBox(height: 7),
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
        const SizedBox(height: 18),
        SectionHeader(title: context.t('settings.security')),
        OutlinedButton.icon(
          icon: const Icon(Icons.lock_outline, size: 16),
          label: Text(context.t('settings.change_password')),
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const ChangePasswordDialog(),
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: embedded ? null : AppBar(title: Text(context.t('profile.title'))),
      body: ViewportScrollPage(
        key: const Key('profile-page-scroll'),
        maxWidth: 980,
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 36),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ApplicantProfileHeader(
              profile: profile,
              name: name,
              onChangePhoto: () => showDialog(
                context: context,
                builder: (_) => const PhotoUploadDialog(),
              ),
              onChangeBanner: () => showDialog(
                context: context,
                builder: (_) => const BannerUploadDialog(),
              ),
              onEdit: () => showDialog(
                context: context,
                builder: (_) => EditProfileDialog(profile: profile),
              ),
            ),
            const SizedBox(height: 18),
            _ProfileCompletion(profile: profile, details: details),
            const SizedBox(height: 20),
            Divider(color: c.border, height: 1),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 760) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      leftColumn,
                      Divider(color: c.border, height: 30),
                      rightColumn,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 11, child: leftColumn),
                    Container(
                      width: 1,
                      constraints: const BoxConstraints(minHeight: 540),
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      color: c.border,
                    ),
                    Expanded(flex: 9, child: rightColumn),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editAbout(
    BuildContext context,
    Map<String, dynamic> details,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('profile.about')),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 6,
            maxLength: 600,
            decoration: InputDecoration(
              hintText: context.tr('profile.about.hint'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(context.tr('common.save')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && context.mounted) {
      await _saveDetails(context, {...details, 'descripcion': value});
    }
  }

  Future<void> _addEntry(
    BuildContext context,
    Map<String, dynamic> details,
    String section,
    String title,
    List<(String, String, bool)> fields,
  ) async {
    final entry = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EntryDialog(title: title, fields: fields),
    );
    if (entry != null && context.mounted) {
      final items = List<dynamic>.from((details[section] as List?) ?? [])
        ..add(entry);
      await _saveDetails(context, {...details, section: items});
    }
  }

  Future<void> _deleteEntry(
    BuildContext context,
    Map<String, dynamic> details,
    String section,
    int index,
  ) async {
    final items = List<dynamic>.from((details[section] as List?) ?? []);
    if (index < 0 || index >= items.length) return;
    items.removeAt(index);
    await _saveDetails(context, {...details, section: items});
  }

  Future<void> _addSkill(
    BuildContext context,
    Map<String, dynamic> details,
  ) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('profile.add_skill')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: context.tr('profile.skill')),
          onSubmitted: (text) => Navigator.pop(dialogContext, text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(context.tr('common.add')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty && context.mounted) {
      final skills = List<dynamic>.from((details['habilidades'] as List?) ?? [])
        ..add(value);
      await _saveDetails(context, {...details, 'habilidades': skills});
    }
  }
}

class _ApplicantProfileHeader extends StatelessWidget {
  const _ApplicantProfileHeader({
    required this.profile,
    required this.name,
    required this.onChangePhoto,
    required this.onChangeBanner,
    required this.onEdit,
  });

  final Map<String, dynamic> profile;
  final String name;
  final VoidCallback onChangePhoto;
  final VoidCallback onChangeBanner;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final subtitle = [
      if ((profile['carrera']?.toString().trim() ?? '').isNotEmpty)
        profile['carrera'].toString().trim(),
      if ((profile['ciudad']?.toString().trim() ?? '').isNotEmpty)
        profile['ciudad'].toString().trim(),
    ].join(' · ');
    final caption = [
      if ((profile['email']?.toString().trim() ?? '').isNotEmpty)
        profile['email'].toString().trim(),
      if ((profile['telefono']?.toString().trim() ?? '').isNotEmpty)
        profile['telefono'].toString().trim(),
    ].join(' · ');

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        final details = profile['perfil'] is Map
            ? Map<String, dynamic>.from(profile['perfil'] as Map)
            : const <String, dynamic>{};
        final bannerUrl =
            profile['banner_url']?.toString().trim() ??
            details['banner_url']?.toString().trim() ??
            '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                if (bannerUrl.isEmpty)
                  BrandGradientPanel(
                    height: compact ? 94 : 112,
                    showBottomLeftRing: false,
                    padding: EdgeInsets.zero,
                    child: const SizedBox.shrink(),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      bannerUrl,
                      height: compact ? 94 : 112,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => BrandGradientPanel(
                        height: compact ? 94 : 112,
                        showBottomLeftRing: false,
                        padding: EdgeInsets.zero,
                        child: const SizedBox.shrink(),
                      ),
                    ),
                  ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: FilledButton.tonalIcon(
                    key: const Key('profile-change-banner'),
                    onPressed: onChangeBanner,
                    icon: const Icon(Icons.image_outlined, size: 15),
                    label: Text(context.t('profile.change_banner')),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 34),
                      backgroundColor: c.surface.withValues(alpha: 0.92),
                      foregroundColor: c.ink,
                    ),
                  ),
                ),
                Positioned(
                  left: compact ? 16 : 24,
                  bottom: -34,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: c.background,
                      shape: BoxShape.circle,
                    ),
                    child: ProfileAvatar(
                      fotoUrl: profile['foto_url']?.toString(),
                      radius: 34,
                      name: name,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 42),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleLarge),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: TextStyle(color: c.inkMuted, fontSize: 12),
                        ),
                      if (caption.isNotEmpty)
                        Text(
                          caption,
                          maxLines: compact ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: c.inkFaint, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (!compact)
                  OutlinedButton.icon(
                    key: const Key('profile-change-photo'),
                    onPressed: onChangePhoto,
                    icon: const Icon(Icons.photo_camera_outlined, size: 15),
                    label: Text(context.t('profile.change_photo')),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                if (!compact) ...[
                  const SizedBox(width: 7),
                  IconButton.outlined(
                    key: const Key('profile-edit-general'),
                    tooltip: context.t('profile.edit'),
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(36, 36),
                      fixedSize: const Size(36, 36),
                      side: BorderSide(color: c.border),
                    ),
                  ),
                ],
              ],
            ),
            if (compact) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('profile-change-photo'),
                      onPressed: onChangePhoto,
                      icon: const Icon(Icons.photo_camera_outlined, size: 15),
                      label: Text(context.t('profile.change_photo')),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                    const SizedBox(width: 7),
                    IconButton.outlined(
                      key: const Key('profile-edit-general'),
                      tooltip: context.t('profile.edit'),
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(36, 36),
                        fixedSize: const Size(36, 36),
                        side: BorderSide(color: c.border),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ProfileCompletion extends StatelessWidget {
  const _ProfileCompletion({required this.profile, required this.details});

  final Map<String, dynamic> profile;
  final Map<String, dynamic> details;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    bool text(Object? value) => value?.toString().trim().isNotEmpty == true;
    bool list(Object? value) => value is List && value.isNotEmpty;
    final checks = [
      text(profile['foto_url']),
      text(profile['nombre_completo']),
      text(profile['email']),
      text(profile['carrera']),
      text(profile['telefono']),
      text(profile['ciudad']),
      text(details['descripcion']),
      list(details['experiencia']),
      list(details['educacion']),
      list(details['certificados']),
      list(details['habilidades']),
      list(details['idiomas']),
      list(details['extras']),
    ];
    final completed = checks.where((value) => value).length;
    final pending = checks.length - completed;
    final progress = completed / checks.length;
    final percent = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context
                    .t('profile.completion')
                    .replaceAll('{percent}', '$percent'),
                style: TextStyle(
                  color: c.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              context.t('profile.pending').replaceAll('{count}', '$pending'),
              style: TextStyle(color: c.inkFaint, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            key: const Key('profile-completion-progress'),
            minHeight: 6,
            value: progress,
            backgroundColor: c.surfaceAlt,
            color: c.accent,
          ),
        ),
        if (pending > 0) ...[
          const SizedBox(height: 7),
          Text(
            context.t('profile.completion.hint'),
            style: TextStyle(color: c.inkMuted, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _SkillsWrap extends StatelessWidget {
  const _SkillsWrap({required this.skills, required this.onDelete});

  final List<dynamic> skills;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) {
      return Text(
        context.t('profile.empty_section'),
        style: TextStyle(
          color: context.colors.inkFaint,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    final visible = skills.length > 8 ? skills.take(8).toList() : skills;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var index = 0; index < visible.length; index++)
              Chip(
                label: Text(visible[index].toString()),
                deleteIcon: const Icon(Icons.close, size: 13),
                onDeleted: () => onDelete(index),
              ),
          ],
        ),
        if (skills.length > visible.length)
          TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (sheetContext) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var index = 0; index < skills.length; index++)
                        Chip(
                          label: Text(skills[index].toString()),
                          deleteIcon: const Icon(Icons.close, size: 13),
                          onDeleted: () {
                            Navigator.pop(sheetContext);
                            onDelete(index);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            child: Text(
              context
                  .t('profile.view_all')
                  .replaceAll('{section}', context.t('profile.skills')),
            ),
          ),
      ],
    );
  }
}

class _ProfileEntrySection extends StatelessWidget {
  const _ProfileEntrySection({
    required this.title,
    required this.icon,
    required this.entries,
    required this.titleKey,
    required this.subtitleKeys,
    required this.onAdd,
    required this.onDelete,
    this.bodyKey,
  });

  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> entries;
  final String titleKey;
  final List<String> subtitleKeys;
  final String? bodyKey;
  final VoidCallback onAdd;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final visibleEntries = entries.length > 3
        ? entries.take(3).toList()
        : entries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: title,
          actionLabel: context.t('common.add'),
          onAction: onAdd,
        ),
        if (entries.isEmpty)
          Text(
            context.t('profile.empty_section'),
            style: TextStyle(
              color: c.inkFaint,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ...List.generate(visibleEntries.length, (index) {
            final entry = visibleEntries[index];
            final subtitle = subtitleKeys
                .map((key) => entry[key]?.toString().trim() ?? '')
                .where((value) => value.isNotEmpty)
                .join(' · ');
            final body = bodyKey == null
                ? ''
                : entry[bodyKey!]?.toString().trim() ?? '';
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.border)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((entry['organizacion_logo']?.toString().trim() ?? '')
                      .isNotEmpty)
                    CompanyAvatar(
                      fotoUrl: entry['organizacion_logo']?.toString(),
                      name:
                          entry['organizacion']?.toString() ??
                          entry['institucion']?.toString(),
                      size: 28,
                    )
                  else
                    Icon(icon, size: 16, color: c.inkFaint),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry[titleKey]?.toString() ?? '—',
                          style: TextStyle(
                            color: c.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: TextStyle(color: c.inkMuted, fontSize: 12),
                          ),
                        if (body.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: c.inkMuted,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: context.t('common.delete'),
                    onPressed: () => onDelete(index),
                    icon: const Icon(Icons.delete_outline, size: 15),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            );
          }),
        if (entries.length > visibleEntries.length)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _showAll(context),
              child: Text(
                context
                    .t('profile.view_all')
                    .replaceAll('{section}', title.toLowerCase()),
              ),
            ),
          ),
        const SizedBox(height: 17),
      ],
    );
  }

  void _showAll(BuildContext context) {
    final c = context.colors;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Text(
                  title,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ),
              Divider(color: c.border, height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) =>
                      Divider(color: c.border, height: 1),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final subtitle = subtitleKeys
                        .map((key) => entry[key]?.toString().trim() ?? '')
                        .where((value) => value.isNotEmpty)
                        .join(' · ');
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CompanyAvatar(
                        fotoUrl: entry['organizacion_logo']?.toString(),
                        name:
                            entry['organizacion']?.toString() ??
                            entry['institucion']?.toString() ??
                            entry[titleKey]?.toString(),
                        size: 34,
                      ),
                      title: Text(entry[titleKey]?.toString() ?? '—'),
                      subtitle: subtitle.isEmpty ? null : Text(subtitle),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryDialog extends StatefulWidget {
  const _EntryDialog({required this.title, required this.fields});

  final String title;
  final List<(String, String, bool)> fields;

  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers = {
    for (final field in widget.fields) field.$1: TextEditingController(),
  };
  List<Map<String, dynamic>> _organizationResults = const [];
  Map<String, dynamic>? _selectedOrganization;
  Timer? _organizationDebounce;
  int _organizationSearchStamp = 0;
  bool _searchingOrganization = false;

  @override
  void dispose() {
    _organizationDebounce?.cancel();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _isOrganizationField(String key) =>
      key == 'organizacion' || key == 'institucion';

  void _searchOrganization(String value) {
    _selectedOrganization = null;
    _organizationDebounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() => _organizationResults = const []);
      return;
    }
    final stamp = ++_organizationSearchStamp;
    _organizationDebounce = Timer(const Duration(milliseconds: 280), () async {
      if (mounted) setState(() => _searchingOrganization = true);
      try {
        final results = await context
            .read<LookUpDataService>()
            .searchOrganizations(query);
        if (mounted && stamp == _organizationSearchStamp) {
          setState(() => _organizationResults = results);
        }
      } catch (_) {
        if (mounted && stamp == _organizationSearchStamp) {
          setState(() => _organizationResults = const []);
        }
      } finally {
        if (mounted && stamp == _organizationSearchStamp) {
          setState(() => _searchingOrganization = false);
        }
      }
    });
  }

  void _selectOrganization(String fieldKey, Map<String, dynamic> organization) {
    final name =
        organization['nombre']?.toString() ??
        organization['nombre_completo']?.toString() ??
        '';
    _controllers[fieldKey]!.text = name;
    setState(() {
      _selectedOrganization = organization;
      _organizationResults = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final field in widget.fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _controllers[field.$1],
                          decoration: InputDecoration(
                            labelText: field.$2,
                            suffixIcon:
                                _isOrganizationField(field.$1) &&
                                    _searchingOrganization
                                ? const Padding(
                                    padding: EdgeInsets.all(13),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : null,
                          ),
                          maxLines: field.$1 == 'descripcion' ? 3 : 1,
                          onChanged: _isOrganizationField(field.$1)
                              ? _searchOrganization
                              : null,
                          validator: field.$3
                              ? (value) => value == null || value.trim().isEmpty
                                    ? context.tr('common.required')
                                    : null
                              : null,
                        ),
                        if (_isOrganizationField(field.$1) &&
                            _organizationResults.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 170),
                            decoration: BoxDecoration(
                              color: context.colors.surface,
                              border: Border.all(color: context.colors.border),
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(10),
                              ),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _organizationResults.length,
                              itemBuilder: (context, index) {
                                final organization =
                                    _organizationResults[index];
                                final name =
                                    organization['nombre']?.toString() ??
                                    organization['nombre_completo']
                                        ?.toString() ??
                                    context.t('common.company');
                                return ListTile(
                                  dense: true,
                                  leading: CompanyAvatar(
                                    fotoUrl:
                                        (organization['foto_url'] ??
                                                organization['logo_url'])
                                            ?.toString(),
                                    name: name,
                                    size: 30,
                                  ),
                                  title: Text(name),
                                  subtitle:
                                      (organization['ciudad']?.toString() ?? '')
                                          .isEmpty
                                      ? null
                                      : Text(organization['ciudad'].toString()),
                                  onTap: () => _selectOrganization(
                                    field.$1,
                                    organization,
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('common.cancel')),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final organization = _selectedOrganization;
            Navigator.pop(context, {
              for (final entry in _controllers.entries)
                entry.key: entry.value.text.trim(),
              if (organization != null)
                'organizacion_id':
                    organization['cuenta_id'] ??
                    organization['empresa_id'] ??
                    organization['organizacion_id'],
              if (organization != null)
                'organizacion_logo':
                    organization['foto_url'] ??
                    organization['logo_url'] ??
                    organization['organizacion_logo'],
            });
          },
          child: Text(context.tr('common.add')),
        ),
      ],
    );
  }
}

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key, required this.profile});

  final Map<String, dynamic> profile;

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _careerController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.profile['nombre_completo']?.toString() ?? '',
    );
    _careerController = TextEditingController(
      text: widget.profile['carrera']?.toString() ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.profile['telefono']?.toString() ?? '',
    );
    _cityController = TextEditingController(
      text: widget.profile['ciudad']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _careerController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<AuthService>().updateProfile({
        'nombre_completo': _nameController.text.trim(),
        'carrera': _careerController.text.trim(),
        'telefono': _phoneController.text.trim(),
        'ciudad': _cityController.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.t('profile.edit')),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: context.t('auth.name'),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? context.tr('auth.name.required')
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _careerController,
                  decoration: InputDecoration(
                    labelText: context.t('auth.career'),
                    prefixIcon: const Icon(Icons.school_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: context.t('auth.phone'),
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: context.t('auth.city'),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(context.tr('common.cancel')),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.tr('common.save')),
        ),
      ],
    );
  }
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await context.read<AuthService>().changePassword(
        _currentController.text,
        _newController.text,
      );
      if (!mounted) return;
      if (updated) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() => _error = context.tr('settings.password.error'));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.t('settings.change_password')),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _currentController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: context.t('settings.password.current'),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? context.tr('auth.password.short')
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: context.t('settings.password.new'),
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                  ),
                  validator: (value) => strongPasswordT(context, value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: context.t('settings.password.confirm'),
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                  ),
                  validator: (value) => value != _newController.text
                      ? context.tr('reset.confirm.mismatch')
                      : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: context.colors.danger)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(context.tr('common.cancel')),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.tr('common.update')),
        ),
      ],
    );
  }
}

class PhotoUploadDialog extends StatefulWidget {
  const PhotoUploadDialog({super.key});

  @override
  State<PhotoUploadDialog> createState() => _PhotoUploadDialogState();
}

class _PhotoUploadDialogState extends State<PhotoUploadDialog> {
  final ImagePicker _picker = ImagePicker();
  final GlobalKey<PhotoCropperState> _cropperKey = GlobalKey();
  Uint8List? _bytes;
  String? _error;
  bool _saving = false;

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 88,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 3 * 1024 * 1024) {
        setState(() => _error = context.tr('photo.too_big'));
        return;
      }
      setState(() {
        _bytes = bytes;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _save() async {
    if (_bytes == null) return;
    setState(() => _saving = true);
    try {
      final png = await _cropperKey.currentState?.exportPng();
      if (!mounted || png == null) {
        setState(() => _error = context.tr('photo.error'));
        return;
      }
      final success = await context.read<AuthService>().uploadProfilePhoto(
        XFile.fromData(png, name: 'perfil.png', mimeType: 'image/png'),
      );
      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
      } else {
        setState(() => _error = context.tr('photo.error'));
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cropSize = (MediaQuery.sizeOf(context).width - 112)
        .clamp(160.0, 260.0)
        .toDouble();
    return AlertDialog(
      title: Text(context.t('photo.title')),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_bytes == null)
                Container(
                  width: cropSize,
                  height: cropSize,
                  decoration: BoxDecoration(
                    color: c.surfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, color: c.inkFaint, size: 64),
                )
              else
                PhotoCropper(
                  key: _cropperKey,
                  imageBytes: _bytes!,
                  size: cropSize,
                ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _saving ? null : _pickImage,
                icon: const Icon(Icons.upload_file_outlined, size: 16),
                label: Text(
                  _bytes == null
                      ? context.t('photo.pick')
                      : context.t('photo.change'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(color: c.danger)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(context.tr('common.cancel')),
        ),
        FilledButton(
          onPressed: _saving || _bytes == null ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.tr('photo.upload')),
        ),
      ],
    );
  }
}

class BannerUploadDialog extends StatefulWidget {
  const BannerUploadDialog({super.key});

  @override
  State<BannerUploadDialog> createState() => _BannerUploadDialogState();
}

class _BannerUploadDialogState extends State<BannerUploadDialog> {
  final ImagePicker _picker = ImagePicker();
  XFile? _file;
  Uint8List? _bytes;
  String? _error;
  bool _saving = false;

  Future<void> _pick() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2200,
        imageQuality: 88,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 5 * 1024 * 1024) {
        setState(() => _error = context.tr('banner.too_big'));
        return;
      }
      setState(() {
        _file = file;
        _bytes = bytes;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _save() async {
    if (_file == null) return;
    setState(() => _saving = true);
    try {
      final success = await context.read<AuthService>().uploadProfileBanner(
        _file!,
      );
      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
      } else {
        setState(() => _error = context.tr('banner.error'));
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AlertDialog(
      title: Text(context.t('banner.title')),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _bytes == null
                    ? ColoredBox(
                        color: c.surfaceAlt,
                        child: Icon(
                          Icons.image_outlined,
                          color: c.inkFaint,
                          size: 42,
                        ),
                      )
                    : Image.memory(_bytes!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pick,
              icon: const Icon(Icons.upload_file_outlined, size: 16),
              label: Text(context.t('banner.pick')),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: c.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(context.tr('common.cancel')),
        ),
        FilledButton(
          onPressed: _saving || _file == null ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.tr('common.save')),
        ),
      ],
    );
  }
}

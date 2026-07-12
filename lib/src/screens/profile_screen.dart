import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/services/auth_service.dart';
import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/services/theme_controller.dart';
import 'package:lookup_user/src/theme.dart';
import 'package:lookup_user/src/utils/formatters.dart';
import 'package:lookup_user/src/widgets/common.dart';
import 'package:lookup_user/src/widgets/photo_cropper.dart';

/// Perfil del postulante: datos, perfil profesional extendido, apariencia,
/// idioma y seguridad.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.embedded = false});

  /// true cuando vive dentro del shell web (sin flecha de volver).
  final bool embedded;

  Map<String, dynamic> _perfilDe(Map<String, dynamic> profile) {
    final raw = profile['perfil'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  Future<void> _guardarPerfil(
    BuildContext context,
    Map<String, dynamic> perfil,
  ) async {
    try {
      await context.read<AuthService>().updateProfile({'perfil': perfil});
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
    final auth = context.watch<AuthService>();
    final themeController = context.watch<ThemeController>();
    final localeController = context.watch<LocaleController>();
    final c = context.colors;
    final profile = auth.profile ?? const <String, dynamic>{};
    final perfil = _perfilDe(profile);
    final nombre =
        profile['nombre_completo']?.toString() ?? context.t('common.applicant');
    final descripcion = perfil['descripcion']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !embedded,
        title: Text(context.t('profile.title')),
        actions: [
          IconButton(
            tooltip: context.t('profile.edit'),
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => EditProfileDialog(profile: profile),
            ),
          ),
        ],
      ),
      body: PageContainer(
        maxWidth: 820,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
          children: [
            // Cabecera estilo perfil profesional: banner + avatar superpuesto
            ProfileBanner(
              avatar: ProfileAvatar(
                fotoUrl: profile['foto_url']?.toString(),
                radius: 44,
                name: nombre,
              ),
              title: nombre,
              subtitle: [
                if ((profile['carrera']?.toString() ?? '').isNotEmpty)
                  profile['carrera'].toString(),
                if ((profile['ciudad']?.toString() ?? '').isNotEmpty)
                  profile['ciudad'].toString(),
              ].join(' · '),
              caption: profile['email']?.toString() ?? '',
              action: OutlinedButton.icon(
                icon: const Icon(Icons.photo_camera_outlined, size: 17),
                label: Text(context.t('profile.change_photo')),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const PhotoUploadDialog(),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Sobre mí
            SectionHeader(
              title: context.t('profile.about'),
              actionLabel: context.t('profile.edit'),
              onAction: () => _editarDescripcion(context, perfil, descripcion),
            ),
            Text(
              descripcion.isEmpty
                  ? context.t('profile.about.hint')
                  : descripcion,
              style: TextStyle(
                color: descripcion.isEmpty ? c.inkFaint : c.ink,
                height: 1.5,
                fontSize: 14.5,
                fontStyle: descripcion.isEmpty ? FontStyle.italic : null,
              ),
            ),
            const SizedBox(height: 22),
            // Datos personales
            SectionHeader(title: context.t('profile.personal')),
            InfoRow(
              icon: Icons.school_outlined,
              label: context.t('auth.career'),
              value:
                  profile['carrera']?.toString() ??
                  context.t('common.not_specified_f'),
            ),
            InfoRow(
              icon: Icons.phone_outlined,
              label: context.t('auth.phone'),
              value:
                  profile['telefono']?.toString() ??
                  context.t('common.not_specified'),
            ),
            InfoRow(
              icon: Icons.location_on_outlined,
              label: context.t('auth.city'),
              value:
                  profile['ciudad']?.toString() ??
                  context.t('common.not_specified_f'),
            ),
            const SizedBox(height: 10),
            // Secciones profesionales
            _EntryListSection(
              title: context.t('profile.experience'),
              icon: Icons.work_outline,
              entries: asMapList(perfil['experiencia']),
              titleKey: 'puesto',
              subtitleKeys: const ['organizacion', 'periodo'],
              bodyKey: 'descripcion',
              onAdd: () => _agregarEntrada(context, perfil, 'experiencia', [
                ('puesto', context.tr('profile.position'), true),
                ('organizacion', context.tr('profile.organization'), true),
                ('periodo', context.tr('profile.period'), false),
                ('descripcion', context.tr('profile.description'), false),
              ], context.tr('profile.add_experience')),
              onDelete: (index) =>
                  _eliminarEntrada(context, perfil, 'experiencia', index),
            ),
            _EntryListSection(
              title: context.t('profile.education'),
              icon: Icons.school_outlined,
              entries: asMapList(perfil['educacion']),
              titleKey: 'titulo',
              subtitleKeys: const ['institucion', 'periodo'],
              onAdd: () => _agregarEntrada(context, perfil, 'educacion', [
                ('titulo', context.tr('profile.degree'), true),
                ('institucion', context.tr('profile.institution'), true),
                ('periodo', context.tr('profile.period'), false),
              ], context.tr('profile.add_education')),
              onDelete: (index) =>
                  _eliminarEntrada(context, perfil, 'educacion', index),
            ),
            _EntryListSection(
              title: context.t('profile.certificates'),
              icon: Icons.verified_outlined,
              entries: asMapList(perfil['certificados']),
              titleKey: 'nombre',
              subtitleKeys: const ['anio'],
              onAdd: () => _agregarEntrada(
                context,
                perfil,
                'certificados',
                [
                  ('nombre', context.tr('profile.cert_name'), true),
                  ('anio', context.tr('profile.year'), false),
                ],
                context.tr('profile.add_certificate'),
              ),
              onDelete: (index) =>
                  _eliminarEntrada(context, perfil, 'certificados', index),
            ),
            // Habilidades (chips)
            SectionHeader(
              title: context.t('profile.skills'),
              actionLabel: context.t('common.add'),
              onAction: () => _agregarHabilidad(context, perfil),
            ),
            if ((perfil['habilidades'] as List?)?.isEmpty ?? true)
              Text(
                context.t('profile.empty_section'),
                style: TextStyle(
                  color: c.inkFaint,
                  fontSize: 13.5,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (
                    var i = 0;
                    i < (perfil['habilidades'] as List).length;
                    i++
                  )
                    Chip(
                      label: Text(
                        (perfil['habilidades'] as List)[i].toString(),
                      ),
                      onDeleted: () {
                        final lista = List<dynamic>.from(
                          perfil['habilidades'] as List,
                        )..removeAt(i);
                        _guardarPerfil(context, {
                          ...perfil,
                          'habilidades': lista,
                        });
                      },
                    ),
                ],
              ),
            const SizedBox(height: 20),
            _EntryListSection(
              title: context.t('profile.languages'),
              icon: Icons.translate_outlined,
              entries: asMapList(perfil['idiomas']),
              titleKey: 'idioma',
              subtitleKeys: const ['nivel'],
              onAdd: () => _agregarEntrada(context, perfil, 'idiomas', [
                ('idioma', context.tr('profile.language'), true),
                ('nivel', context.tr('profile.level'), false),
              ], context.tr('profile.add_language')),
              onDelete: (index) =>
                  _eliminarEntrada(context, perfil, 'idiomas', index),
            ),
            _EntryListSection(
              title: context.t('profile.extras'),
              subtitle: context.t('profile.extras.hint'),
              icon: Icons.star_outline,
              entries: asMapList(perfil['extras']),
              titleKey: 'titulo',
              subtitleKeys: const [],
              bodyKey: 'descripcion',
              onAdd: () => _agregarEntrada(context, perfil, 'extras', [
                ('titulo', context.tr('profile.extra_title'), true),
                ('descripcion', context.tr('profile.description'), false),
              ], context.tr('profile.add_extra')),
              onDelete: (index) =>
                  _eliminarEntrada(context, perfil, 'extras', index),
            ),
            const SizedBox(height: 10),
            // Configuración
            SectionHeader(title: context.t('settings.title')),
            Text(
              context.t('settings.theme'),
              style: TextStyle(fontSize: 13.5, color: c.inkMuted),
            ),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(context.t('settings.theme.light')),
                  icon: const Icon(Icons.light_mode_outlined, size: 17),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(context.t('settings.theme.dark')),
                  icon: const Icon(Icons.dark_mode_outlined, size: 17),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(context.t('settings.theme.system')),
                  icon: const Icon(Icons.brightness_auto_outlined, size: 17),
                ),
              ],
              selected: {themeController.mode},
              onSelectionChanged: (selection) =>
                  themeController.setMode(selection.first),
            ),
            const SizedBox(height: 16),
            Text(
              context.t('settings.language'),
              style: TextStyle(fontSize: 13.5, color: c.inkMuted),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'es', label: Text('Español')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {localeController.language},
              onSelectionChanged: (selection) =>
                  localeController.setLanguage(selection.first),
            ),
            const SizedBox(height: 24),
            // Seguridad
            SectionHeader(title: context.t('settings.security')),
            OutlinedButton.icon(
              icon: const Icon(Icons.lock_outline),
              label: Text(context.t('settings.change_password')),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const ChangePasswordDialog(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editarDescripcion(
    BuildContext context,
    Map<String, dynamic> perfil,
    String actual,
  ) async {
    final controller = TextEditingController(text: actual);
    final resultado = await showDialog<String>(
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
    if (resultado != null && context.mounted) {
      await _guardarPerfil(context, {...perfil, 'descripcion': resultado});
    }
  }

  Future<void> _agregarEntrada(
    BuildContext context,
    Map<String, dynamic> perfil,
    String seccion,
    List<(String, String, bool)> campos,
    String titulo,
  ) async {
    final entrada = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _EntryDialog(titulo: titulo, campos: campos),
    );
    if (entrada != null && context.mounted) {
      final lista = List<dynamic>.from((perfil[seccion] as List?) ?? [])
        ..add(entrada);
      await _guardarPerfil(context, {...perfil, seccion: lista});
    }
  }

  Future<void> _eliminarEntrada(
    BuildContext context,
    Map<String, dynamic> perfil,
    String seccion,
    int index,
  ) async {
    final lista = List<dynamic>.from((perfil[seccion] as List?) ?? []);
    if (index < 0 || index >= lista.length) return;
    lista.removeAt(index);
    await _guardarPerfil(context, {...perfil, seccion: lista});
  }

  Future<void> _agregarHabilidad(
    BuildContext context,
    Map<String, dynamic> perfil,
  ) async {
    final controller = TextEditingController();
    final valor = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('profile.add_skill')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: context.tr('profile.skill')),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
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
    if (valor != null && valor.isNotEmpty && context.mounted) {
      final lista = List<dynamic>.from((perfil['habilidades'] as List?) ?? [])
        ..add(valor);
      await _guardarPerfil(context, {...perfil, 'habilidades': lista});
    }
  }
}

/// Sección con lista de entradas (experiencia, educación, etc.).
class _EntryListSection extends StatelessWidget {
  const _EntryListSection({
    required this.title,
    required this.icon,
    required this.entries,
    required this.titleKey,
    required this.subtitleKeys,
    required this.onAdd,
    required this.onDelete,
    this.bodyKey,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          actionLabel: context.t('common.add'),
          onAction: onAdd,
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              subtitle!,
              style: TextStyle(color: c.inkFaint, fontSize: 12.5),
            ),
          ),
        if (entries.isEmpty)
          Text(
            context.t('profile.empty_section'),
            style: TextStyle(
              color: c.inkFaint,
              fontSize: 13.5,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ...List.generate(entries.length, (i) {
            final entry = entries[i];
            final sub = subtitleKeys
                .map((k) => entry[k]?.toString() ?? '')
                .where((v) => v.isNotEmpty)
                .join(' · ');
            final body = bodyKey == null
                ? ''
                : (entry[bodyKey!]?.toString() ?? '');
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.border)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 19, color: c.inkFaint),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry[titleKey]?.toString() ?? '—',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: c.ink,
                            fontSize: 14.5,
                          ),
                        ),
                        if (sub.isNotEmpty)
                          Text(
                            sub,
                            style: TextStyle(color: c.inkMuted, fontSize: 13),
                          ),
                        if (body.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              body,
                              style: TextStyle(
                                color: c.inkMuted,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: context.t('common.delete'),
                    onPressed: () => onDelete(i),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 19,
                      color: c.inkFaint,
                    ),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 18),
      ],
    );
  }
}

/// Diálogo genérico para añadir una entrada con campos de texto.
class _EntryDialog extends StatefulWidget {
  const _EntryDialog({required this.titulo, required this.campos});

  final String titulo;

  /// (clave, etiqueta, requerido)
  final List<(String, String, bool)> campos;

  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers = {
    for (final campo in widget.campos) campo.$1: TextEditingController(),
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final campo in widget.campos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _controllers[campo.$1],
                      decoration: InputDecoration(labelText: campo.$2),
                      maxLines: campo.$1 == 'descripcion' ? 3 : 1,
                      validator: campo.$3
                          ? (value) => value == null || value.trim().isEmpty
                                ? context.tr('common.required')
                                : null
                          : null,
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
            Navigator.pop(context, {
              for (final entry in _controllers.entries)
                entry.key: entry.value.text.trim(),
            });
          },
          child: Text(context.tr('common.add')),
        ),
      ],
    );
  }
}

/// Diálogo para editar los datos básicos del postulante.
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
  bool _isSaving = false;

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
    setState(() => _isSaving = true);
    try {
      await context.read<AuthService>().updateProfile({
        'nombre_completo': _nameController.text.trim(),
        'carrera': _careerController.text.trim(),
        'telefono': _phoneController.text.trim(),
        'ciudad': _cityController.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(context.t('common.cancel')),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.t('common.save')),
        ),
      ],
    );
  }
}

/// Diálogo para cambiar la contraseña.
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _actualController = TextEditingController();
  final _nuevaController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _actualController.dispose();
    _nuevaController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final ok = await context.read<AuthService>().changePassword(
        _actualController.text,
        _nuevaController.text,
      );
      if (!mounted) return;
      if (ok) {
        // AuthService cierra la sesión porque el backend revoca los tokens.
        // SessionGate mostrará el acceso y el aviso correspondiente.
        return;
      } else {
        setState(() => _error = context.tr('settings.password.error'));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
                  controller: _actualController,
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
                  controller: _nuevaController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: context.t('settings.password.new'),
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    helperText: context.t('auth.password.hint'),
                    helperMaxLines: 2,
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
                  validator: (value) => value != _nuevaController.text
                      ? context.tr('reset.confirm.mismatch')
                      : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: context.colors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(context.t('common.cancel')),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.t('common.update')),
        ),
      ],
    );
  }
}

/// Diálogo de foto de perfil con recorte y zoom (acercar/alejar).
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
  bool _isSaving = false;

  Future<void> _pickImage() async {
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
  }

  Future<void> _save() async {
    if (_bytes == null) {
      setState(() => _error = context.tr('photo.pick_first'));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final png = await _cropperKey.currentState?.exportPng();
      if (!mounted) return;
      if (png == null) {
        setState(() => _error = context.tr('photo.error'));
        return;
      }
      final file = XFile.fromData(
        png,
        name: 'perfil.png',
        mimeType: 'image/png',
      );
      final success = await context.read<AuthService>().uploadProfilePhoto(
        file,
      );
      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
      } else {
        setState(() => _error = context.tr('photo.error'));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AlertDialog(
      title: Text(context.t('photo.title')),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_bytes == null)
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: c.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: c.inkFaint, size: 72),
              )
            else ...[
              PhotoCropper(key: _cropperKey, imageBytes: _bytes!),
              const SizedBox(height: 4),
              Text(
                context.t('photo.adjust'),
                textAlign: TextAlign.center,
                style: TextStyle(color: c.inkFaint, fontSize: 12),
              ),
            ],
            const SizedBox(height: 14),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: Text(
                _bytes == null
                    ? context.t('photo.pick')
                    : context.t('photo.change'),
              ),
              onPressed: _isSaving ? null : _pickImage,
            ),
            const SizedBox(height: 6),
            Text(
              context.t('photo.formats'),
              textAlign: TextAlign.center,
              style: TextStyle(color: c.inkFaint, fontSize: 12),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.danger, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(context.t('common.cancel')),
        ),
        FilledButton(
          onPressed: _isSaving || _bytes == null ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.t('photo.upload')),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/screens/forgot_password_screen.dart';
import 'package:lookup_user/src/services/api_service.dart';
import 'package:lookup_user/src/services/auth_service.dart';
import 'package:lookup_user/src/services/data_service.dart';
import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/theme.dart';
import 'package:lookup_user/src/utils/formatters.dart';
import 'package:lookup_user/src/utils/portal_links.dart';
import 'package:lookup_user/src/widgets/common.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _careerController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isRegistering = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_refreshPasswordHint);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthService>();
      if (auth.consumePasswordChangedNotice()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('settings.password.updated'))),
        );
      }
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_refreshPasswordHint);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _careerController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _refreshPasswordHint() {
    if (mounted && _isRegistering) setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final auth = context.read<AuthService>();

    try {
      final success = _isRegistering
          ? await auth.register(
              nombreCompleto: _nameController.text,
              email: _emailController.text,
              password: _passwordController.text,
              carrera: _careerController.text,
              ciudad: _cityController.text,
            )
          : await auth.login(_emailController.text, _passwordController.text);
      if (!mounted || !success) return;
      final cuentaId = auth.cuentaId;
      if (cuentaId != null) {
        await context.read<LookUpDataService>().refresh(cuentaId);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.tr('common.error.connection'));
      }
    }
  }

  Future<void> _openRecruiterPortal() async {
    var opened = false;
    try {
      opened = await PortalLinks.openRecruiterPortal();
    } catch (_) {}
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('auth.company.unavailable'))),
      );
    }
  }

  void _changeMode(bool registering) {
    setState(() {
      _isRegistering = registering;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isRegistering ? _buildRegistration(context) : _buildLogin(context);
  }

  Widget _buildLogin(BuildContext context) {
    final auth = context.watch<AuthService>();
    final c = context.colors;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 840;
            final form = _LoginForm(
              formKey: _formKey,
              emailController: _emailController,
              passwordController: _passwordController,
              hidePassword: _hidePassword,
              isLoading: auth.isLoading,
              error: _error,
              onTogglePassword: () =>
                  setState(() => _hidePassword = !_hidePassword),
              onSubmit: _submit,
              onForgot: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              ),
              onRegister: () => _changeMode(true),
              onOpenRecruiterPortal: _openRecruiterPortal,
            );

            if (!wide) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    BrandGradientPanel(
                      height: 256,
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                      borderRadius: BorderRadius.zero,
                      child: const _ApplicantLoginHero(compact: true),
                    ),
                    ColoredBox(
                      color: c.background,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 28, 22, 36),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 390),
                            child: form,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Row(
              children: [
                Expanded(
                  child: BrandGradientPanel(
                    padding: const EdgeInsets.fromLTRB(52, 48, 52, 40),
                    borderRadius: BorderRadius.zero,
                    child: const _ApplicantLoginHero(),
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    color: c.background,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(40),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 390),
                          child: form,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRegistration(BuildContext context) {
    final auth = context.watch<AuthService>();
    final c = context.colors;
    final english = Localizations.localeOf(context).languageCode == 'en';
    final careerSuggestions = english
        ? const [
            'Systems Engineering',
            'Software Development',
            'Business Administration',
            'Accounting',
            'UX/UI Design',
            'Marketing',
          ]
        : const [
            'Ingeniería de Sistemas',
            'Desarrollo de Software',
            'Administración',
            'Contabilidad',
            'Diseño UX/UI',
            'Marketing',
          ];
    const citySuggestions = [
      'Lima',
      'Arequipa',
      'Trujillo',
      'Chiclayo',
      'Piura',
      'Cusco',
      'Chimbote',
    ];
    final passwordIsValid =
        _passwordController.text.isNotEmpty &&
        strongPasswordT(context, _passwordController.text) == null;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 58,
        leading: IconButton(
          tooltip: context.t('common.back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: auth.isLoading ? null : () => _changeMode(false),
        ),
        title: Text(context.t('auth.register.title')),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: BrandMark(size: 54)),
                    const SizedBox(height: 24),
                    _FieldLabel(context.t('auth.name')),
                    TextFormField(
                      key: const Key('register-name-field'),
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) => requiredField(
                        value,
                        context.tr('auth.name.required'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel(context.t('auth.email')),
                    TextFormField(
                      key: const Key('register-email-field'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, fieldConstraints) {
                        final sideBySide = fieldConstraints.maxWidth >= 500;
                        final career = Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FieldLabel(context.t('auth.career')),
                            _EditableAutocompleteField(
                              fieldKey: const Key('register-career-field'),
                              controller: _careerController,
                              suggestions: careerSuggestions,
                              icon: Icons.school_outlined,
                            ),
                          ],
                        );
                        final city = Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FieldLabel(context.t('auth.city')),
                            _EditableAutocompleteField(
                              fieldKey: const Key('register-city-field'),
                              controller: _cityController,
                              suggestions: citySuggestions,
                              icon: Icons.location_on_outlined,
                            ),
                          ],
                        );
                        if (!sideBySide) {
                          return Column(
                            children: [
                              career,
                              const SizedBox(height: 14),
                              city,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: career),
                            const SizedBox(width: 12),
                            Expanded(child: city),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel(context.t('auth.password')),
                    TextFormField(
                      key: const Key('register-password-field'),
                      controller: _passwordController,
                      obscureText: _hidePassword,
                      onFieldSubmitted: (_) =>
                          auth.isLoading ? null : _submit(),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => strongPasswordT(context, value),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          passwordIsValid
                              ? Icons.check_circle
                              : Icons.info_outline,
                          size: 15,
                          color: passwordIsValid ? c.success : c.inkFaint,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            context.t('auth.password.hint'),
                            style: TextStyle(
                              color: passwordIsValid ? c.success : c.inkMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (_error != null) ErrorBanner(message: _error!),
                    FilledButton(
                      key: const Key('register-submit'),
                      onPressed: auth.isLoading ? null : _submit,
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(context.t('auth.register')),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          context.t('auth.have_account.question'),
                          style: TextStyle(color: c.inkMuted, fontSize: 12.5),
                        ),
                        TextButton(
                          onPressed: auth.isLoading
                              ? null
                              : () => _changeMode(false),
                          child: Text(context.t('auth.login')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return valid ? null : context.tr('auth.email.invalid');
  }
}

class _ApplicantLoginHero extends StatelessWidget {
  const _ApplicantLoginHero({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final benefits = [
      context.t('auth.hero.benefit.verified'),
      context.t('auth.hero.benefit.progress'),
      context.t('auth.hero.benefit.contact'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BrandMark(size: 38),
        SizedBox(height: compact ? 24 : 64),
        Text(
          context.t('auth.hero.title'),
          style:
              (compact
                      ? Theme.of(context).textTheme.headlineSmall
                      : Theme.of(context).textTheme.headlineLarge)
                  ?.copyWith(color: Colors.white),
        ),
        SizedBox(height: compact ? 14 : 24),
        if (compact)
          Text(
            benefits.first,
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          )
        else
          ...benefits.map(
            (benefit) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kSkyBlue,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      benefit,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!compact) ...[
          const Spacer(),
          Text(
            context.t('auth.hero.footer'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.hidePassword,
    required this.isLoading,
    required this.error,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onForgot,
    required this.onRegister,
    required this.onOpenRecruiterPortal,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool hidePassword;
  final bool isLoading;
  final String? error;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onForgot;
  final VoidCallback onRegister;
  final VoidCallback onOpenRecruiterPortal;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.t('auth.login.heading'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          _FieldLabel(context.t('auth.email')),
          TextFormField(
            key: const Key('login-email-field'),
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              final email = value?.trim() ?? '';
              return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                  ? null
                  : context.tr('auth.email.invalid');
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              _FieldLabel(context.t('auth.password')),
              TextButton(
                onPressed: isLoading ? null : onForgot,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 28),
                ),
                child: Text(context.t('auth.forgot')),
              ),
            ],
          ),
          TextFormField(
            key: const Key('login-password-field'),
            controller: passwordController,
            obscureText: hidePassword,
            onFieldSubmitted: (_) => isLoading ? null : onSubmit(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: onTogglePassword,
                icon: Icon(
                  hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) => value == null || value.length < 8
                ? context.tr('auth.password.short')
                : null,
          ),
          const SizedBox(height: 18),
          if (error != null) ErrorBanner(message: error!),
          FilledButton(
            key: const Key('login-submit'),
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(context.t('auth.login')),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                context.t('auth.no_account'),
                style: TextStyle(color: c.inkMuted, fontSize: 12),
              ),
              TextButton(
                onPressed: isLoading ? null : onRegister,
                child: Text(context.t('auth.create_account')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Divider(color: c.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  context.t('auth.company.question'),
                  style: TextStyle(color: c.inkFaint, fontSize: 12),
                ),
              ),
              Expanded(child: Divider(color: c.border)),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('open-recruiter-portal'),
            onPressed: isLoading ? null : onOpenRecruiterPortal,
            icon: const Icon(Icons.business_center_outlined, size: 17),
            label: Text(context.t('auth.company.action')),
          ),
        ],
      ),
    );
  }
}

class _EditableAutocompleteField extends StatelessWidget {
  const _EditableAutocompleteField({
    required this.fieldKey,
    required this.controller,
    required this.suggestions,
    required this.icon,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final List<String> suggestions;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) => Autocomplete<String>(
        initialValue: TextEditingValue(text: controller.text),
        displayStringForOption: (option) => option,
        optionsBuilder: (value) {
          final query = normalizeSearchText(value.text);
          if (query.isEmpty) return suggestions;
          return suggestions.where(
            (option) => normalizeSearchText(option).contains(query),
          );
        },
        onSelected: (option) => controller.text = option,
        fieldViewBuilder:
            (context, textController, focusNode, onFieldSubmitted) {
              return TextFormField(
                key: fieldKey,
                controller: textController,
                focusNode: focusNode,
                textInputAction: TextInputAction.next,
                onChanged: (value) => controller.text = value,
                onFieldSubmitted: (_) => onFieldSubmitted(),
                decoration: InputDecoration(
                  prefixIcon: Icon(icon),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
              );
            },
        optionsViewBuilder: (context, onSelected, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: c.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: c.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: constraints.maxWidth,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 190),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return InkWell(
                      onTap: () => onSelected(option),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 11,
                        ),
                        child: Text(
                          option,
                          style: TextStyle(color: c.ink, fontSize: 12.5),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: context.colors.inkMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

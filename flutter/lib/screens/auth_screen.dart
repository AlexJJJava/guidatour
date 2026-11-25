import 'package:flutter/material.dart';

import '../l10n/labels.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import '../legal_texts.dart';
import 'legal_screen.dart';

/// Account demo per velocizzare i test manuali: TOGLIERE prima del lancio
/// reale (o quando la registrazione vera sostituisce questi dati finti).
const _demoAccounts = [
  ('Turista', 'alessio.damico+turista1@gmail.com'),
  ('Guida', 'alessio.damico+guida1@gmail.com'),
  ('Accompagnatore', 'alessio.damico+accompagnatore1@gmail.com'),
  ('Guida + Accomp.', 'alessio.damico+multi1@gmail.com'),
  ('Tour operator', 'alessio.damico+operator1@gmail.com'),
  ('Admin', 'alessio.damico+admin1@gmail.com'),
];
const _demoPassword = 'GuidaTour2026!';

/// Accesso / registrazione con email e password (Supabase Auth).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _hidden = true;
  bool _terms = false;
  bool _busy = false;

  /// Ruoli professionali scelti; nessuno = turista.
  final Set<Role> _roles = {};

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = l10n(context);
    if (!_formKey.currentState!.validate()) return;
    if (_register && !_terms) {
      snack(context, t.authAcceptTerms);
      return;
    }
    setState(() => _busy = true);
    final msg = _register
        ? await appState
            .registerWithPassword(_name.text, _email.text, _password.text, [
            for (final r in professionalRoles)
              if (_roles.contains(r)) r
          ])
        : await appState.loginWithPassword(_email.text, _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (msg != null) snack(context, msg);
  }

  Future<void> _quickLogin(String email) async {
    setState(() => _busy = true);
    final msg = await appState.loginWithPassword(email, _demoPassword);
    if (!mounted) return;
    setState(() => _busy = false);
    if (msg != null) snack(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    // Fascia del titolo larga come nelle altre pagine; il modulo resta
    // stretto e centrato, più comodo da compilare.
    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
              title: _register ? t.authCreateAccountTitle : t.authLoginTitle,
              icon: Icons.lock_outline),
          const SizedBox(height: 16),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(t.authIntro, style: const TextStyle(color: kMuted)),
                    if (!_register) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kSand,
                          borderRadius: BorderRadius.circular(kRadiusSm),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Solo per test — accesso rapido',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final (label, email) in _demoAccounts)
                                  OutlinedButton(
                                    onPressed:
                                        _busy ? null : () => _quickLogin(email),
                                    child: Text(label),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _ComingSoonSocialButton(label: t.authGoogle),
                    const SizedBox(height: 8),
                    _ComingSoonSocialButton(label: t.authFacebook),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(t.authOrEmail,
                              style: const TextStyle(color: kMuted)),
                        ),
                        const Expanded(child: Divider()),
                      ]),
                    ),
                    if (_register) ...[
                      TextFormField(
                        controller: _name,
                        decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            labelText: t.fieldName,
                            border: const OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? t.validationRequired
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          labelText: t.fieldEmail,
                          border: const OutlineInputBorder()),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? t.validationEmail
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidden,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        labelText: t.fieldPassword,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_hidden
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(() => _hidden = !_hidden),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? t.validationPasswordLength
                          : null,
                    ),
                    if (!_register)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          key: const ValueKey('forgot-password'),
                          onPressed: _busy
                              ? null
                              : () => _showResetDialog(context, _email.text),
                          child: Text(t.authForgotPassword),
                        ),
                      ),
                    if (_register) ...[
                      const SizedBox(height: 16),
                      Text(t.authRoleTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(t.authRolesHint,
                          style: const TextStyle(fontSize: 13, color: kMuted)),
                      for (final r in professionalRoles)
                        CheckboxListTile(
                          key: ValueKey('role-${r.name}'),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _roles.contains(r),
                          onChanged: (v) => setState(() =>
                              v == true ? _roles.add(r) : _roles.remove(r)),
                          title: Text(roleLabel(context, r)),
                          subtitle: Text(switch (r) {
                            Role.guida => t.authRoleDescGuida,
                            Role.accompagnatore => t.authRoleDescAccompagnatore,
                            _ => t.authRoleDescTourOperator,
                          }),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: Text(
                            _roles.isEmpty
                                ? t.authRolesTourist
                                : t.authRolesPro(rolesLabel(context, [
                                    for (final r in professionalRoles)
                                      if (_roles.contains(r)) r
                                  ])),
                            key: const ValueKey('roles-summary'),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _terms,
                        onChanged: (v) => setState(() => _terms = v ?? false),
                        title: Text(t.authTermsText,
                            style: const TextStyle(fontSize: 13)),
                      ),
                      const LegalLink(kind: LegalKind.terms),
                      const LegalLink(kind: LegalKind.privacy),
                    ],
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(_register ? t.register : t.login),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _register = !_register),
                      child:
                          Text(_register ? t.authHaveAccount : t.authNoAccount),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chiede l'email e invia il link per reimpostare la password. Il messaggio
/// di conferma è lo stesso anche per email non registrate.
Future<void> _showResetDialog(BuildContext context, String email) async {
  final sent = await showDialog<bool>(
    context: context,
    builder: (_) => _ResetPasswordDialog(initialEmail: email),
  );
  if (sent == true && context.mounted) {
    snack(context, l10n(context).authResetSent);
  }
}

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.initialEmail});
  final String initialEmail;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail.trim());
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final msg = await appState.sendPasswordReset(_email.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (msg != null) {
      snack(context, msg);
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return AlertDialog(
      title: Text(t.authResetTitle),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.authResetIntro, style: const TextStyle(color: kMuted)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    labelText: t.fieldEmail,
                    border: const OutlineInputBorder()),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? t.validationEmail : null,
                onFieldSubmitted: (_) => _busy ? null : _send(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _send,
          child: Text(t.authResetSend),
        ),
      ],
    );
  }
}

/// Dopo il link dell'email l'utente è già collegato: si sceglie la nuova
/// password. Chiudere senza salvare lascia la password di prima.
Future<void> showNewPasswordDialog(BuildContext context) async {
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _NewPasswordDialog(),
  );
  if (saved != true) appState.passwordRecovery.value = false;
  if (saved == true && context.mounted) {
    snack(context, l10n(context).authPasswordUpdated);
  }
}

class _NewPasswordDialog extends StatefulWidget {
  const _NewPasswordDialog();

  @override
  State<_NewPasswordDialog> createState() => _NewPasswordDialogState();
}

class _NewPasswordDialogState extends State<_NewPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hidden = true;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final msg = await appState.updatePassword(_password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (msg != null) {
      snack(context, msg);
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final eye = IconButton(
      icon: Icon(_hidden ? Icons.visibility_off : Icons.visibility),
      onPressed: () => setState(() => _hidden = !_hidden),
    );
    return AlertDialog(
      title: Text(t.authNewPasswordTitle),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.authNewPasswordIntro,
                  style: const TextStyle(color: kMuted)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                autofocus: true,
                obscureText: _hidden,
                decoration: InputDecoration(
                    labelText: t.fieldNewPassword,
                    border: const OutlineInputBorder(),
                    suffixIcon: eye),
                validator: (v) => (v == null || v.length < 6)
                    ? t.validationPasswordLength
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: _hidden,
                decoration: InputDecoration(
                    labelText: t.fieldConfirmPassword,
                    border: const OutlineInputBorder()),
                validator: (v) =>
                    v != _password.text ? t.validationPasswordMismatch : null,
                onFieldSubmitted: (_) => _busy ? null : _save(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(t.save),
        ),
      ],
    );
  }
}

/// Google/Facebook richiedono un'app OAuth su Google Cloud Console / Meta for
/// Developers collegata a Supabase: non ancora configurata.
class _ComingSoonSocialButton extends StatelessWidget {
  const _ComingSoonSocialButton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(vertical: 6),
      ),
      onPressed: () => snack(context, t.authSocialComingSoon(label)),
      icon: const Icon(Icons.lock_clock_outlined, size: 20),
      label: Text(t.authSocialLabel(label)),
    );
  }
}

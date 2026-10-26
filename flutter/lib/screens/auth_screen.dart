import 'package:flutter/material.dart';

import '../auth_service.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';

/// Accesso / registrazione professionisti (prototipo senza backend).
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
  Role _role = Role.turista;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_register) {
      if (!_terms) {
        snack(context, 'Accetta i termini d’uso per registrarti.');
        return;
      }
      appState.register(_name.text.trim(), _email.text.trim(), _role);
    } else {
      final err = appState.login(_email.text);
      if (err != null) snack(context, err);
    }
  }

  bool _busy = false;

  Future<void> _social(String provider) async {
    setState(() => _busy = true);
    final profile = await socialAuth.signIn(provider);
    if (!mounted) return;
    setState(() => _busy = false);
    if (profile == null) return;
    final existing = appState.findByEmail(profile.email);
    if (existing != null) {
      appState.loginAs(existing);
      return;
    }
    // Primo accesso: serve il tipo di profilo e l'accettazione dei termini.
    final role = await _askRole();
    if (role == null) return;
    appState.register(profile.name, profile.email, role,
        provider: profile.provider);
  }

  Future<Role?> _askRole() {
    var role = Role.turista;
    var terms = false;
    return showDialog<Role>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Completa il profilo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Con che ruolo usi GuidaTour?'),
                RadioGroup<Role>(
                  groupValue: role,
                  onChanged: (v) => setLocal(() => role = v!),
                  child: Column(
                    children: [
                      for (final r in Role.values)
                        RadioListTile<Role>(
                          contentPadding: EdgeInsets.zero,
                          value: r,
                          title: Text(r.label),
                        ),
                    ],
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: terms,
                  onChanged: (v) => setLocal(() => terms = v ?? false),
                  title: const Text(
                      'Accetto i termini d’uso e l’informativa privacy.',
                      style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla')),
            FilledButton(
              onPressed: terms ? () => Navigator.pop(ctx, role) : null,
              child: const Text('Continua'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialButton(String provider, String label, IconData icon) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(vertical: 6),
      ),
      onPressed: _busy ? null : () => _social(provider),
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      maxWidth: 480,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_register ? 'Crea il tuo account' : 'Accedi o registrati',
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w800, color: kInk)),
            const SizedBox(height: 8),
            const Text(
                'Salva i tuoi tour preferiti e chiedi disponibilità, oppure pubblica i tuoi tour se sei una guida o un operatore.',
                style: TextStyle(color: kMuted)),
            const SizedBox(height: 24),
            _socialButton('google', 'Continua con Google', Icons.g_mobiledata),
            const SizedBox(height: 8),
            _socialButton('facebook', 'Continua con Facebook', Icons.facebook),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child:
                      Text('oppure con email', style: TextStyle(color: kMuted)),
                ),
                Expanded(child: Divider()),
              ]),
            ),
            if (_register) ...[
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    labelText: 'Nome / ragione sociale',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  labelText: 'Email',
                  border: OutlineInputBorder()),
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Inserisci un’email valida'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _hidden,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_hidden ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _hidden = !_hidden),
                ),
              ),
              validator: (v) => (_register && (v == null || v.length < 6))
                  ? 'Almeno 6 caratteri'
                  : null,
            ),
            if (_register) ...[
              const SizedBox(height: 16),
              const Text('Tipo di profilo',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              RadioGroup<Role>(
                groupValue: _role,
                onChanged: (v) => setState(() => _role = v!),
                child: Column(
                  children: [
                    for (final r in Role.values)
                      RadioListTile<Role>(
                        contentPadding: EdgeInsets.zero,
                        value: r,
                        title: Text(r.label),
                        subtitle: Text(switch (r) {
                          Role.turista =>
                            'Preferiti, carrello e storico delle tue richieste.',
                          Role.guida => 'Pubblica visite guidate svolte da te.',
                          Role.accompagnatore =>
                            'Assistenza e supporto operativo ai gruppi; non visite guidate specialistiche.',
                          Role.tourOperator =>
                            'Pacchetti completi e collaborazione con guide. Richiede verifica.',
                        }),
                      ),
                  ],
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _terms,
                onChanged: (v) => setState(() => _terms = v ?? false),
                title: const Text(
                    'Accetto i termini d’uso: GuidaTour è intermediario tecnologico e '
                    'promozionale. Se sono un professionista, sono responsabile di contenuti, '
                    'abilitazione e svolgimento delle mie offerte.',
                    style: TextStyle(fontSize: 13)),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _submit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_register ? 'Registrati' : 'Accedi'),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _register = !_register),
              child: Text(_register
                  ? 'Hai già un account? Accedi'
                  : 'Non hai un account? Registrati'),
            ),
            if (!_register) ...[
              const Divider(height: 32),
              const Text('Account demo (senza password)',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final g in appState.guides)
                    ActionChip(
                      avatar: const Icon(Icons.person_outline, size: 18),
                      label: Text('${g.name} · ${g.role.label}'),
                      onPressed: () => appState.loginAs(g),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

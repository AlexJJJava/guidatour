import 'package:flutter/material.dart';

import '../l10n/labels.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _key = GlobalKey<FormState>();
  late final Guide _user = appState.currentUser!;
  late final _name = TextEditingController(text: _user.name);
  late final _bio = TextEditingController(text: _user.bio);
  late final Set<String> _languages = {..._user.languages};
  late String _city = _user.city;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = l10n(context);
    if (!_key.currentState!.validate()) return;
    if (_languages.isEmpty) {
      snack(context, t.validationAtLeastOneLanguage);
      return;
    }
    setState(() => _saving = true);
    try {
      await appState.updateProfile(
        name: _name.text.trim(),
        bio: _bio.text.trim(),
        languages: _languages.toList(),
        city: _user.role.isProfessional ? _city : null,
      );
      if (!mounted) return;
      snack(context, t.profileSaved);
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        snack(context, '$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.editProfile)),
      body: PageBody(
        maxWidth: 560,
        child: Form(
          key: _key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                    labelText: t.fieldName, border: const OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? t.validationRequired : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _bio,
                maxLines: 4,
                decoration: InputDecoration(
                    labelText: t.fieldBio, border: const OutlineInputBorder()),
              ),
              if (_user.role.isProfessional) ...[
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _city,
                  decoration: InputDecoration(
                      labelText: t.fieldCity,
                      border: const OutlineInputBorder()),
                  items: [
                    for (final c in tourCities)
                      DropdownMenuItem(
                          value: c, child: Text(cityLabel(context, c))),
                  ],
                  onChanged: (v) => setState(() => _city = v!),
                ),
              ],
              const SizedBox(height: 18),
              Text(t.fieldLanguagesSpoken,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final l in tourLanguages)
                    FilterChip(
                      label: Text(languageLabel(context, l)),
                      selected: _languages.contains(l),
                      onSelected: (v) => setState(
                          () => v ? _languages.add(l) : _languages.remove(l)),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(t.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

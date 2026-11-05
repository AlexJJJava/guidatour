import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/labels.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'avatar_crop_screen.dart';

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
  bool _photoBusy = false;

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

  Future<void> _pickPhoto() async {
    final t = l10n(context);
    final navigator = Navigator.of(context);
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final png = await navigator.push<Uint8List>(
        MaterialPageRoute(builder: (_) => AvatarCropScreen(bytes: bytes)));
    if (png == null) return;
    await _changePhoto(() => appState.uploadAvatar(png), t.avatarSaved);
  }

  Future<void> _changePhoto(Future<void> Function() action, String done) async {
    final t = l10n(context);
    setState(() => _photoBusy = true);
    try {
      await action();
      if (mounted) snack(context, done);
    } catch (_) {
      if (mounted) snack(context, t.avatarError);
    }
    if (mounted) setState(() => _photoBusy = false);
  }

  Widget _photo(BuildContext context) {
    final t = l10n(context);
    final user = appState.currentUser ?? _user;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle),
          child: UserAvatar(user: user, radius: 52),
        ),
        const SizedBox(height: 12),
        if (_photoBusy)
          const CircularProgressIndicator(color: kPrimary)
        else
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: Text(
                    user.avatarUrl == null ? t.avatarUpload : t.avatarChange),
              ),
              if (user.avatarUrl != null)
                TextButton(
                  onPressed: () =>
                      _changePhoto(appState.removeAvatar, t.avatarRemoved),
                  child: Text(t.avatarRemove),
                ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return Scaffold(
      body: PageBody(
        title: t.editProfile,
        maxWidth: 640,
        child: Form(
          key: _key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GoldPanel(
                title: t.profilePhotoSection,
                icon: Icons.photo_camera_outlined,
                child: _photo(context),
              ),
              const SizedBox(height: 16),
              GoldPanel(
                title: t.profileDataSection,
                icon: Icons.badge_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: InputDecoration(
                          labelText: t.fieldName,
                          border: const OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? t.validationRequired
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _bio,
                      maxLines: 4,
                      decoration: InputDecoration(
                          labelText: t.fieldBio,
                          border: const OutlineInputBorder()),
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
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GoldPanel(
                title: t.fieldLanguagesSpoken,
                icon: Icons.translate,
                child: Wrap(
                  runSpacing: 6,
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

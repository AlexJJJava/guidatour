import 'package:flutter/material.dart';

import '../l10n/labels.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'poster_screen.dart';

/// Parole che indicano visite specialistiche su beni culturali (BRD §13.4).
const _culturalKeywords = [
  'museo',
  'musei',
  'colosseo',
  'foro',
  'scavi',
  'catacombe',
  'monument',
  'basilica',
  'vaticano',
  'archeolog',
  'galleria',
];

class TourFormScreen extends StatefulWidget {
  const TourFormScreen({super.key, this.existing});

  /// Se valorizzato, il form modifica questo tour invece di crearne uno nuovo.
  final Tour? existing;

  @override
  State<TourFormScreen> createState() => _TourFormScreenState();
}

class _TourFormScreenState extends State<TourFormScreen> {
  final _key = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _duration =
      TextEditingController(text: widget.existing?.duration ?? '2 ore');
  late final _price =
      TextEditingController(text: widget.existing?.price.toString());
  late final _meeting =
      TextEditingController(text: widget.existing?.meetingPoint);
  late final _description =
      TextEditingController(text: widget.existing?.description);
  late final _seats =
      TextEditingController(text: (widget.existing?.seats ?? 10).toString());
  late String _city = widget.existing?.city ?? appState.city;
  late String _category = widget.existing?.category ?? tourCategories.first;
  late String _language = widget.existing?.language ?? tourLanguages.first;
  late DateTime? _start = widget.existing?.start;
  late final Set<String> _accessories = {...?widget.existing?.accessories};
  bool _declaration = false;

  bool get _isEdit => widget.existing != null;

  Guide get _user => appState.currentUser!;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _declaration = true;
    if (!_isEdit && _user.role == Role.accompagnatore) {
      _category = 'Accompagnamento';
    }
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _duration,
      _price,
      _meeting,
      _description,
      _seats
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Restituisce il motivo del blocco, o null se si può pubblicare.
  String? _blockReason(BuildContext context) {
    final t = l10n(context);
    final role = _user.role;
    if (_accessories.isNotEmpty) {
      if (role != Role.tourOperator) {
        return t.formBlockAccessoriesNotOperator(
            _accessories.map((a) => accessoryLabel(context, a)).join(', '),
            roleLabel(context, role));
      }
      if (!_user.verified) {
        return t.formBlockNotVerified;
      }
    }
    if (role == Role.accompagnatore) {
      final text = '${_title.text} ${_description.text}'.toLowerCase();
      if (_category != 'Accompagnamento') {
        return t.formBlockAccompagnatoreCategory;
      }
      if (_culturalKeywords.any(text.contains)) {
        return t.formBlockCulturalKeywords;
      }
    }
    return null;
  }

  bool _submitting = false;

  Future<void> _submit() async {
    final t = l10n(context);
    if (!_key.currentState!.validate()) return;
    if (_start == null) {
      snack(context, t.formChooseDateTime);
      return;
    }
    if (_blockReason(context) != null) return;
    if (!_declaration) {
      snack(context, t.formConfirmDeclaration);
      return;
    }
    setState(() => _submitting = true);
    try {
      if (_isEdit) {
        await appState.updateTour(
          widget.existing!.id,
          title: _title.text.trim(),
          city: _city,
          category: _category,
          language: _language,
          duration: _duration.text.trim(),
          start: _start!,
          price: double.parse(_price.text.replaceAll(',', '.')),
          meetingPoint: _meeting.text.trim(),
          description: _description.text.trim(),
          seats: int.parse(_seats.text),
          accessories: _accessories.toList(),
        );
        if (!mounted) return;
        Navigator.of(context).pop(true);
        return;
      }
      final tour = await appState.addTour(
        title: _title.text.trim(),
        city: _city,
        category: _category,
        language: _language,
        duration: _duration.text.trim(),
        start: _start!,
        price: double.parse(_price.text.replaceAll(',', '.')),
        meetingPoint: _meeting.text.trim(),
        description: _description.text.trim(),
        seats: int.parse(_seats.text),
        accessories: _accessories.toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PosterScreen(tour: tour)),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        snack(context, '$e');
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _start ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 10, minute: 0));
    if (t == null) return;
    setState(() => _start = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final block = _blockReason(context);
    final categories = _user.role == Role.accompagnatore
        ? tourCategories
        : tourCategories.where((c) => c != 'Accompagnamento').toList();
    if (!categories.contains(_category)) _category = categories.first;
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? t.validationRequired : null;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? t.editTour : t.newTour)),
      body: PageBody(
        maxWidth: 680,
        child: Form(
          key: _key,
          onChanged: () => setState(() {}),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InfoBanner(t.formPublishingAs(roleLabel(context, _user.role))),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                decoration: InputDecoration(
                    labelText: t.fieldTourTitle, border: const OutlineInputBorder()),
                validator: required,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _city,
                decoration: InputDecoration(
                    labelText: t.fieldCity, border: const OutlineInputBorder()),
                items: [
                  for (final c in tourCities)
                    DropdownMenuItem(value: c, child: Text(cityLabel(context, c))),
                ],
                onChanged: (v) => setState(() => _city = v!),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                    labelText: t.fieldCategory, border: const OutlineInputBorder()),
                items: [
                  for (final c in categories)
                    DropdownMenuItem(value: c, child: Text(categoryLabel(context, c))),
                ],
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _language,
                decoration: InputDecoration(
                    labelText: t.fieldLanguage, border: const OutlineInputBorder()),
                items: [
                  for (final l in tourLanguages)
                    DropdownMenuItem(value: l, child: Text(languageLabel(context, l))),
                ],
                onChanged: (v) => setState(() => _language = v!),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event),
                label: Text(_start == null ? t.fieldDateTime : fmtDate(_start!)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _duration,
                      decoration: InputDecoration(
                          labelText: t.fieldDuration, border: const OutlineInputBorder()),
                      validator: required,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: t.fieldPrice,
                          border: const OutlineInputBorder()),
                      validator: (v) =>
                          double.tryParse((v ?? '').replaceAll(',', '.')) ==
                                  null
                              ? t.validationNumber
                              : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _seats,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: t.fieldSeats, border: const OutlineInputBorder()),
                      validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1
                          ? t.validationAtLeastOne
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _meeting,
                decoration: InputDecoration(
                    labelText: t.fieldMeetingPoint,
                    border: const OutlineInputBorder()),
                validator: required,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                maxLines: 4,
                decoration: InputDecoration(
                    labelText: t.fieldDescription, border: const OutlineInputBorder()),
                validator: required,
              ),
              const SizedBox(height: 18),
              Text(t.fieldAccessories,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Wrap(
                spacing: 8,
                children: [
                  for (final s in accessoryServices)
                    FilterChip(
                      label: Text(accessoryLabel(context, s)),
                      selected: _accessories.contains(s),
                      onSelected: (v) => setState(() =>
                          v ? _accessories.add(s) : _accessories.remove(s)),
                    ),
                ],
              ),
              if (block != null) ...[
                const SizedBox(height: 14),
                InfoBanner(block, warning: true),
              ],
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _declaration,
                onChanged: (v) => setState(() => _declaration = v ?? false),
                title: Text(t.formDeclaration, style: const TextStyle(fontSize: 13)),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: block == null && !_submitting ? _submit : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isEdit ? t.formSubmitEdit : t.formSubmit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
  'pinacoteca',
  'visita guidata',
  'visite guidate',
  'guida turistica',
  'guida abilitata',
  'beni culturali',
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
  late String _city = widget.existing?.city ?? _user.city;
  late String _category = widget.existing?.category ?? tourCategories.first;
  late String _language = widget.existing?.language ?? tourLanguages.first;

  /// Date del tour in ordine; in modifica restano solo quelle future.
  late final List<DateTime> _dates = [...?widget.existing?.upcoming];
  late final Set<String> _accessories = {...?widget.existing?.accessories};
  bool _declaration = false;

  bool get _isEdit => widget.existing != null;

  Guide get _user => appState.currentUser!;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _declaration = true;
    if (!_isEdit && _user.onlyAccompagnatore) {
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
    if (_accessories.isNotEmpty) {
      if (!_user.has(Role.tourOperator)) {
        return t.formBlockAccessoriesNotOperator(
            _accessories.map((a) => accessoryLabel(context, a)).join(', '),
            rolesLabel(context, _user.roles));
      }
    }
    if (_user.onlyAccompagnatore) {
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
    if (!_dates.any((d) => d.isAfter(DateTime.now()))) {
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
          dates: _dates,
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
        dates: _dates,
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

  void _setDates(Iterable<DateTime> more) {
    final all = {..._dates, ...more}.toList()..sort();
    if (all.length > maxTourDates) {
      snack(context, l10n(context).formMaxDates(maxTourDates));
    }
    setState(() => _dates
      ..clear()
      ..addAll(all.take(maxTourDates)));
  }

  /// Aggiunge una data: giorno e ora (l'ora proposta è quella dell'ultima data).
  Future<void> _addDate() async {
    final now = DateTime.now();
    final last = _dates.isEmpty ? null : _dates.last;
    final d = await showDatePicker(
      context: context,
      initialDate: last != null && last.isAfter(now)
          ? last.add(const Duration(days: 7))
          : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
        context: context,
        initialTime: last != null
            ? TimeOfDay.fromDateTime(last)
            : const TimeOfDay(hour: 10, minute: 0));
    if (t == null) return;
    _setDates([DateTime(d.year, d.month, d.day, t.hour, t.minute)]);
  }

  /// Ripete l'ultima data ogni settimana, stessa ora, fino al giorno scelto.
  Future<void> _repeatWeekly() async {
    final last = _dates.last;
    final first = last.add(const Duration(days: 7));
    final until = await showDatePicker(
      context: context,
      helpText: l10n(context).formRepeatUntil,
      initialDate: last.add(const Duration(days: 28)),
      firstDate: first,
      lastDate: last.add(const Duration(days: 7 * 26)),
    );
    if (until == null || !mounted) return;
    _setDates(weeklyDates(last, until));
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final block = _blockReason(context);
    // L'accompagnamento a chi è accompagnatore, le altre categorie a guide e
    // tour operator.
    final categories = [
      for (final c in tourCategories)
        if (c == 'Accompagnamento'
            ? _user.has(Role.accompagnatore)
            : !_user.onlyAccompagnatore)
          c,
    ];
    if (!categories.contains(_category)) _category = categories.first;
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? t.validationRequired : null;
    return Scaffold(
      body: PageBody(
        title: _isEdit ? t.editTour : t.newTour,
        icon: Icons.add_location_alt_outlined,
        maxWidth: 680,
        child: Form(
          key: _key,
          onChanged: () => setState(() {}),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InfoBanner(t.formPublishingAs(rolesLabel(context, _user.roles))),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                decoration: InputDecoration(
                    labelText: t.fieldTourTitle,
                    border: const OutlineInputBorder()),
                validator: required,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _city,
                decoration: InputDecoration(
                    labelText: t.fieldCity, border: const OutlineInputBorder()),
                items: [
                  for (final c in tourCities)
                    DropdownMenuItem(
                        value: c, child: Text(cityLabel(context, c))),
                ],
                onChanged: (v) => setState(() => _city = v!),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                    labelText: t.fieldCategory,
                    border: const OutlineInputBorder()),
                items: [
                  for (final c in categories)
                    DropdownMenuItem(
                        value: c, child: Text(categoryLabel(context, c))),
                ],
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _language,
                decoration: InputDecoration(
                    labelText: t.fieldLanguage,
                    border: const OutlineInputBorder()),
                items: [
                  for (final l in tourLanguages)
                    DropdownMenuItem(
                        value: l, child: Text(languageLabel(context, l))),
                ],
                onChanged: (v) => setState(() => _language = v!),
              ),
              const SizedBox(height: 14),
              Text(t.fieldDates,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              if (_dates.isEmpty)
                Text(t.formNoDates, style: const TextStyle(color: kMuted))
              else
                Wrap(
                  key: const ValueKey('tour-dates'),
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final d in _dates)
                      InputChip(
                        avatar: const Icon(Icons.event, size: 18),
                        label: Text(fmtDate(d)),
                        onDeleted: () => setState(() => _dates.remove(d)),
                      ),
                  ],
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('add-date'),
                    onPressed: _addDate,
                    icon: const Icon(Icons.add),
                    label: Text(t.formAddDate),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('repeat-weekly'),
                    onPressed: _dates.isEmpty ? null : _repeatWeekly,
                    icon: const Icon(Icons.repeat),
                    label: Text(t.formRepeatWeekly),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(builder: (context, c) {
                const gap = 12.0;
                final w =
                    c.maxWidth < 440 ? c.maxWidth : (c.maxWidth - gap * 2) / 3;
                return Wrap(
                  spacing: gap,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: w,
                      child: TextFormField(
                        controller: _duration,
                        decoration: InputDecoration(
                            labelText: t.fieldDuration,
                            border: const OutlineInputBorder()),
                        validator: required,
                      ),
                    ),
                    SizedBox(
                      width: w,
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
                    SizedBox(
                      width: w,
                      child: TextFormField(
                        controller: _seats,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            labelText: t.fieldSeats,
                            border: const OutlineInputBorder()),
                        validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1
                            ? t.validationAtLeastOne
                            : null,
                      ),
                    ),
                  ],
                );
              }),
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
                    labelText: t.fieldDescription,
                    border: const OutlineInputBorder()),
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
              if (_user.onlyAccompagnatore) ...[
                const SizedBox(height: 14),
                InfoBanner(t.accompagnatoreNotice),
              ],
              if (block != null) ...[
                const SizedBox(height: 14),
                InfoBanner(block, warning: true),
              ],
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _declaration,
                onChanged: (v) => setState(() => _declaration = v ?? false),
                title: Text(t.formDeclaration,
                    style: const TextStyle(fontSize: 13)),
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

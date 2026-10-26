import 'package:flutter/material.dart';

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
  const TourFormScreen({super.key});

  @override
  State<TourFormScreen> createState() => _TourFormScreenState();
}

class _TourFormScreenState extends State<TourFormScreen> {
  final _key = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _duration = TextEditingController(text: '2 ore');
  final _price = TextEditingController();
  final _meeting = TextEditingController();
  final _description = TextEditingController();
  final _seats = TextEditingController(text: '10');
  String _category = tourCategories.first;
  String _language = tourLanguages.first;
  DateTime? _start;
  final Set<String> _accessories = {};
  bool _declaration = false;

  Guide get _user => appState.currentUser!;

  @override
  void initState() {
    super.initState();
    if (_user.role == Role.accompagnatore) _category = 'Accompagnamento';
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
  String? _blockReason() {
    final role = _user.role;
    if (_accessories.isNotEmpty) {
      if (role != Role.tourOperator) {
        return 'Con servizi accessori (${_accessories.join(', ')}) l’offerta diventa un '
            'pacchetto turistico. Il profilo ${role.label} può pubblicare solo la propria '
            'visita o attività: rimuovi i servizi accessori oppure usa un profilo Tour operator verificato.';
      }
      if (!_user.verified) {
        return 'I pacchetti completi richiedono un profilo Tour operator verificato. '
            'Il tuo profilo è in attesa di verifica.';
      }
    }
    if (role == Role.accompagnatore) {
      final text = '${_title.text} ${_description.text}'.toLowerCase();
      if (_category != 'Accompagnamento') {
        return 'L’accompagnatore turistico può pubblicare solo attività di accompagnamento, '
            'non visite guidate: la categoria è riservata alla guida abilitata.';
      }
      if (_culturalKeywords.any(text.contains)) {
        return 'Il testo sembra descrivere una visita guidata specialistica su beni culturali, '
            'riservata alla guida abilitata. Riformula come attività di accompagnamento o '
            'invia a revisione amministrativa.';
      }
    }
    return null;
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    if (_start == null) {
      snack(context, 'Scegli data e ora.');
      return;
    }
    if (_blockReason() != null) return;
    if (!_declaration) {
      snack(context, 'Conferma la dichiarazione di responsabilità.');
      return;
    }
    final tour = appState.addTour(
      title: _title.text.trim(),
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => PosterScreen(tour: tour)),
    );
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

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null;

  @override
  Widget build(BuildContext context) {
    final block = _blockReason();
    final categories = _user.role == Role.accompagnatore
        ? tourCategories
        : tourCategories.where((c) => c != 'Accompagnamento').toList();
    if (!categories.contains(_category)) _category = categories.first;
    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo tour')),
      body: PageBody(
        maxWidth: 680,
        child: Form(
          key: _key,
          onChanged: () => setState(() {}),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InfoBanner(
                  'Stai pubblicando come ${_user.role.label}. Città: Roma.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                    labelText: 'Titolo del tour', border: OutlineInputBorder()),
                validator: _required,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                    labelText: 'Categoria', border: OutlineInputBorder()),
                items: [
                  for (final c in categories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _language,
                decoration: const InputDecoration(
                    labelText: 'Lingua', border: OutlineInputBorder()),
                items: [
                  for (final l in tourLanguages)
                    DropdownMenuItem(value: l, child: Text(l)),
                ],
                onChanged: (v) => setState(() => _language = v!),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event),
                label: Text(_start == null ? 'Data e ora' : fmtDate(_start!)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _duration,
                      decoration: const InputDecoration(
                          labelText: 'Durata', border: OutlineInputBorder()),
                      validator: _required,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Prezzo (€)',
                          border: OutlineInputBorder()),
                      validator: (v) =>
                          double.tryParse((v ?? '').replaceAll(',', '.')) ==
                                  null
                              ? 'Numero'
                              : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _seats,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Posti', border: OutlineInputBorder()),
                      validator: (v) =>
                          (int.tryParse(v ?? '') ?? 0) < 1 ? '≥ 1' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _meeting,
                decoration: const InputDecoration(
                    labelText: 'Punto di incontro',
                    border: OutlineInputBorder()),
                validator: _required,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Descrizione', border: OutlineInputBorder()),
                validator: _required,
              ),
              const SizedBox(height: 18),
              const Text('Servizi accessori inclusi',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              Wrap(
                spacing: 8,
                children: [
                  for (final s in accessoryServices)
                    FilterChip(
                      label: Text(s),
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
                title: const Text(
                    'Dichiaro di essere responsabile del contenuto pubblicato, della mia '
                    'abilitazione (ove richiesta), della disponibilità e dello svolgimento '
                    'dell’offerta.',
                    style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: block == null ? _submit : null,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Pubblica e genera QR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../state.dart';
import '../widgets.dart';

/// Opt-in WhatsApp consent-first (BRD §13.1): il consenso è esplicito e tracciato.
class WhatsAppOptInCard extends StatefulWidget {
  const WhatsAppOptInCard({super.key, required this.source});
  final String source;

  @override
  State<WhatsAppOptInCard> createState() => _WhatsAppOptInCardState();
}

class _WhatsAppOptInCardState extends State<WhatsAppOptInCard> {
  final _phone = TextEditingController();
  bool _consent = false;
  bool _done = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    final phone = _phone.text.trim();
    if (phone.replaceAll(RegExp(r'\D'), '').length < 8) {
      snack(context, 'Inserisci un numero di telefono valido.');
      return;
    }
    if (!_consent) {
      snack(context, 'Serve il consenso esplicito per procedere.');
      return;
    }
    appState.addConsent(phone, widget.source);
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE9F3F0),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _done
            ? const Row(
                children: [
                  Icon(Icons.check_circle, color: kPrimary),
                  SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          'Fatto! Riceverai su WhatsApp la lista aggiornata dei tour a Roma. '
                          'Puoi annullare in qualsiasi momento rispondendo STOP.')),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      'Vuoi ricevere su WhatsApp la lista aggiornata delle escursioni a Roma?',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: kInk)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Numero WhatsApp',
                      hintText: '+39 …',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _consent,
                    onChanged: (v) => setState(() => _consent = v ?? false),
                    title: const Text(AppState.whatsappConsentText,
                        style: TextStyle(fontSize: 13)),
                  ),
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.chat),
                    label: const Text('Ricevi la lista su WhatsApp'),
                  ),
                ],
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../l10n/labels.dart';
import '../state.dart';
import '../widgets.dart';

/// Opt-in WhatsApp consent-first (BRD §13.1): il consenso è esplicito e tracciato.
///
/// Il testo del checkbox resta sempre in italiano in ogni lingua dell'app:
/// è la prova legale del consenso (coincide con quanto il backend registra
/// come "ciò che l'utente ha visto", vedi BR-011D), quindi non va tradotto
/// solo lato UI mentre il backend conserva l'originale italiano.
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
  bool _sending = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = l10n(context);
    final phone = _phone.text.trim();
    if (!RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(phone)) {
      snack(context, t.whatsappInvalidPhone);
      return;
    }
    if (!_consent) {
      snack(context, t.whatsappNeedConsent);
      return;
    }
    setState(() => _sending = true);
    try {
      await appState.addConsent(phone, widget.source);
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        snack(context, '$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return Material(
      color: kSand,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: _done
            ? Row(
                children: [
                  const Icon(Icons.check_circle, color: kPrimary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(t.whatsappDone)),
                ],
              )
            : LayoutBuilder(builder: (context, c) {
                final title = Text(t.whatsappTitle,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kInk));
                final phone = TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: t.fieldWhatsappNumber,
                    hintText: t.whatsappHint,
                    filled: true,
                    fillColor: kSurface,
                    border: const OutlineInputBorder(),
                  ),
                );
                final button = FilledButton.icon(
                  onPressed: _sending ? null : _submit,
                  icon: const Icon(Icons.chat),
                  label: Text(t.whatsappSubmit),
                );
                final consent = CheckboxListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _consent,
                  onChanged: (v) => setState(() => _consent = v ?? false),
                  title: const Text(AppState.whatsappConsentText,
                      style: TextStyle(fontSize: 12)),
                );
                // Su schermi larghi titolo, numero e pulsante su una riga.
                if (c.maxWidth >= 760) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: title),
                        const SizedBox(width: 16),
                        SizedBox(width: 260, child: phone),
                        const SizedBox(width: 12),
                        button,
                      ]),
                      consent,
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 10),
                    phone,
                    consent,
                    button,
                  ],
                );
              }),
      ),
    );
  }
}

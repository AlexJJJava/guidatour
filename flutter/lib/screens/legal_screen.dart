import 'package:flutter/material.dart';

import '../app_config.dart';
import '../l10n/labels.dart';
import '../legal_texts.dart';
import '../widgets.dart';

/// Informativa privacy o termini d'uso, nella lingua scelta.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.kind});
  final LegalKind kind;

  /// Nome della pagina per [ShellScope.open]: niente doppioni dal footer.
  static String routeName(LegalKind kind) => 'legal-${kind.name}';

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final privacy = kind == LegalKind.privacy;
    final sections =
        legalSections(kind, Localizations.localeOf(context).languageCode);
    return Scaffold(
      body: PageBody(
        title: privacy ? t.privacyTitle : t.termsTitle,
        subtitle: privacy ? t.privacySub : t.termsSub,
        icon: privacy ? Icons.shield_outlined : Icons.gavel_outlined,
        child: Container(
          padding: const EdgeInsets.fromLTRB(kGapXl, 20, kGapXl, kGapXl),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: kLine),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.legalUpdated(legalUpdatedOn),
                  style: const TextStyle(fontSize: 12, color: kMuted)),
              for (final (title, paragraphs) in sections) ...[
                const SizedBox(height: 22),
                Text(title,
                    style: const TextStyle(
                        fontFamily: kSerif,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: kInk)),
                const SizedBox(height: kGapSm),
                for (final p in paragraphs) _Paragraph(p),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 15, height: 1.55, color: kInk);
    final bullet = text.startsWith('• ');
    return Padding(
      padding: EdgeInsets.only(bottom: kGapSm, left: bullet ? kGapSm : 0),
      child: bullet
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  ',
                    style:
                        TextStyle(color: kPrimary, height: 1.55, fontSize: 15)),
                Expanded(child: Text(text.substring(2), style: style)),
              ],
            )
          : Text(text, style: style),
    );
  }
}

/// Link testuale che apre informativa o termini (moduli e consensi).
class LegalLink extends StatelessWidget {
  const LegalLink({super.key, required this.kind});
  final LegalKind kind;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        key: ValueKey('legal-link-${kind.name}'),
        onPressed: () => openLegal(context, kind),
        style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact),
        icon: Icon(
            kind == LegalKind.privacy
                ? Icons.shield_outlined
                : Icons.gavel_outlined,
            size: 16),
        label: Text(
            kind == LegalKind.privacy ? t.legalReadPrivacy : t.legalReadTerms),
      ),
    );
  }
}

/// Apre la pagina sotto intestazione e footer (o sopra, fuori dall'app).
void openLegal(BuildContext context, LegalKind kind) {
  final shell = context.getInheritedWidgetOfExactType<ShellScope>();
  final page = LegalScreen(kind: kind);
  if (shell != null) {
    shell.open(page, name: LegalScreen.routeName(kind));
  } else {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

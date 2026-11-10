import 'package:flutter/material.dart';

import '../l10n/labels.dart';
import '../widgets.dart';

/// Domande frequenti, raggiungibili dal footer.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final faqs = [
      (t.faq1Q, t.faq1A),
      (t.faq2Q, t.faq2A),
      (t.faq3Q, t.faq3A),
      (t.faq4Q, t.faq4A),
      (t.faq5Q, t.faq5A),
      (t.faq6Q, t.faq6A),
      (t.faq7Q, t.faq7A),
    ];
    return Scaffold(
      body: PageBody(
        title: t.faqTitle,
        subtitle: t.pageFaqSub,
        icon: Icons.help_outline,
        child: Column(
          children: [
            for (final (q, a) in faqs)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  shape: const Border(),
                  title: Text(q,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a, style: const TextStyle(height: 1.5, color: kInk)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

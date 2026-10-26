import 'package:flutter/material.dart';

import 'models.dart';
import 'state.dart';

const kPrimary = Color(0xFF0F766E);
const kInk = Color(0xFF183A36);
const kMuted = Color(0xFF6D817C);

/// Centra il contenuto e limita la larghezza (browser/tablet).
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child, this.maxWidth = 1240});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(wide ? 48 : 20, 26, wide ? 48 : 20, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(
      {super.key, required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: kInk)),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid(
      {super.key, required this.children, this.itemHeight = 116});
  final List<Widget> children;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 620 ? 2 : 1);
      const gap = 10.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children)
            SizedBox(width: w, height: itemHeight, child: child),
        ],
      );
    });
  }
}

const _categoryIcons = {
  'Visita guidata': Icons.account_balance_outlined,
  'Tour a piedi': Icons.directions_walk,
  'Enogastronomico': Icons.restaurant_outlined,
  'Bambini e famiglie': Icons.child_care,
  'Serale': Icons.nightlight_outlined,
  'Accompagnamento': Icons.groups_outlined,
};

IconData categoryIcon(String c) => _categoryIcons[c] ?? Icons.explore_outlined;

class TourCard extends StatelessWidget {
  const TourCard({super.key, required this.tour, required this.onTap});
  final Tour tour;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final guide = appState.guideById(tour.guideId);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE0E8E3)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                color: const Color(0xFFE6D3B3),
                child: Center(
                  child: Icon(categoryIcon(tour.category),
                      size: 34, color: Colors.white.withValues(alpha: 0.9)),
                ),
              ),
            ),
            Expanded(
              flex: 7,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tour.category} · ${tour.language}'.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 9,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w700,
                          color: kMuted),
                    ),
                    const SizedBox(height: 3),
                    Text(tour.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: kInk)),
                    const SizedBox(height: 2),
                    Text(
                      '${guide?.name ?? ''} · ${guide?.role.label ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: kMuted),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 13, color: kMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(fmtDate(tour.start),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11)),
                        ),
                        Text(fmtPrice(tour.price),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: kPrimary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner(this.text, {super.key, this.warning = false});
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning ? const Color(0xFFFFF1D6) : const Color(0xFFE9F3F0);
    final fg = warning ? const Color(0xFF7A4B00) : kPrimary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(warning ? Icons.warning_amber_rounded : Icons.info_outline,
              size: 20, color: fg),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text, style: TextStyle(color: fg, height: 1.35))),
        ],
      ),
    );
  }
}

/// Disclaimer sul ruolo della piattaforma nell'MVP (BRD §15.1).
class PlatformDisclaimer extends StatelessWidget {
  const PlatformDisclaimer({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: 24),
        child: Text(
          'GuidaTour è una piattaforma di promozione e contatto: non organizza i '
          'tour né incassa pagamenti. Disponibilità, conferma, pagamento ed '
          'esecuzione restano in capo a guida od operatore che pubblica l’offerta.',
          style: TextStyle(fontSize: 12, color: kMuted, height: 1.4),
        ),
      );
}

void snack(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

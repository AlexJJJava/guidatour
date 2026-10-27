import 'package:flutter/material.dart';

import 'l10n/labels.dart';
import 'l10n/locale_controller.dart';
import 'models.dart';
import 'state.dart';

const kPrimary = Color(0xFF0F766E);
const kInk = Color(0xFF183A36);
const kMuted = Color(0xFF6D817C);

/// Raggio d'angolo condiviso da card e contenitori arrotondati.
const kRadius = 14.0;

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
      {super.key, required this.children, this.itemHeight = 136});
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

/// Un colore d'accento diverso per categoria: rende le liste più vive senza
/// bisogno di immagini.
const _categoryColors = {
  'Visita guidata': Color(0xFFCC8B5C),
  'Tour a piedi': Color(0xFF6FA287),
  'Enogastronomico': Color(0xFFD9A441),
  'Bambini e famiglie': Color(0xFF5B9BB0),
  'Serale': Color(0xFF6C66A8),
  'Accompagnamento': Color(0xFFB08968),
};

Color categoryColor(String c) => _categoryColors[c] ?? kPrimary;

class TourCard extends StatelessWidget {
  const TourCard({super.key, required this.tour, required this.onTap});
  final Tour tour;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final guide = appState.guideById(tour.guideId);
    final roleText = guide == null ? '' : roleLabel(context, guide.role);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Hero(
                tag: 'tour-color-${tour.id}',
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        categoryColor(tour.category),
                        categoryColor(tour.category).withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(categoryIcon(tour.category),
                        size: 34, color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 7,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${categoryLabel(context, tour.category)} · ${languageLabel(context, tour.language)}'
                          .toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w700,
                          color: kMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(tour.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 18,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            color: kInk)),
                    const SizedBox(height: 3),
                    Text(
                      '${guide?.name ?? ''} · $roleText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: kMuted),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 15, color: kMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(fmtDate(tour.start),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13)),
                        ),
                        Text(fmtPrice(tour.price),
                            style: const TextStyle(
                                fontSize: 16,
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

/// Stato vuoto curato (icona + messaggio) al posto di un semplice testo.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: kPrimary),
            ),
            const SizedBox(height: 14),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kMuted)),
          ],
        ),
      ),
    );
  }
}

/// Disclaimer sul ruolo della piattaforma nell'MVP (BRD §15.1).
class PlatformDisclaimer extends StatelessWidget {
  const PlatformDisclaimer({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Text(
          l10n(context).platformDisclaimer,
          style: const TextStyle(fontSize: 12, color: kMuted, height: 1.4),
        ),
      );
}

/// Selettore della città: filtra i tour mostrati in tutta l'app (come un
/// marketplace di tour tipo GetYourGuide).
class CityPicker extends StatelessWidget {
  const CityPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return PopupMenuButton<String>(
          tooltip: l10n(context).fieldCity,
          initialValue: appState.city,
          onSelected: (c) => appState.setCity(c),
          itemBuilder: (context) => [
            for (final c in tourCities)
              PopupMenuItem(value: c, child: Text(cityLabel(context, c))),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE1F0EC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, size: 18, color: kPrimary),
                const SizedBox(width: 6),
                Text(cityLabel(context, appState.city),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: kInk)),
                const Icon(Icons.expand_more, size: 18, color: kMuted),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Selettore di lingua (IT/EN/ES), sempre visibile in alto a destra.
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeController,
      builder: (context, locale, _) {
        return Material(
          color: Colors.white,
          elevation: 1,
          borderRadius: BorderRadius.circular(20),
          child: PopupMenuButton<Locale>(
            tooltip: localeDisplayName(locale),
            initialValue: locale,
            onSelected: localeController.setLocale,
            itemBuilder: (context) => [
              for (final l in supportedLocales)
                PopupMenuItem(value: l, child: Text(localeDisplayName(l))),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language, size: 18, color: kPrimary),
                  const SizedBox(width: 6),
                  Text(locale.languageCode.toUpperCase(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: kInk)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

void snack(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

/// Esegue una chiamata al backend mostrando l'errore in uno snackbar se fallisce.
Future<void> runOrSnack(
    BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (e) {
    if (context.mounted) snack(context, '$e');
  }
}

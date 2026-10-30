import 'package:flutter/material.dart';

import 'l10n/labels.dart';
import 'l10n/locale_controller.dart';
import 'models.dart';
import 'state.dart';

/// Oro scuro: icone, link e accenti su fondo chiaro.
const kPrimary = Color(0xFFB4832F);

/// Oro chiaro dei pulsanti principali.
const kGold = Color(0xFFF2C36B);

/// Testo sopra i pulsanti oro.
const kOnGold = Color(0xFF1E2A33);

/// Oro dei titoli in corsivo sulle foto.
const kGoldText = Color(0xFFF0C878);
const kInk = Color(0xFF1E2A33);
const kMuted = Color(0xFF6B6F76);

/// Sfondo delle pagine.
const kCream = Color(0xFFFBF7F0);

/// Card, riquadri e sezioni alternate.
const kSurface = Colors.white;
const kSand = Color(0xFFF6EEDF);
const kLine = Color(0xFFEAE2D3);

/// Blu notte di intestazione e footer.
const kNight = Color(0xFF1F2A33);

/// Font dei titoli (Playfair Display, vedi pubspec).
const kSerif = 'Playfair';

/// Raggio d'angolo condiviso da card e contenitori arrotondati.
const kRadius = 12.0;

/// Etichetta maiuscola e spaziata sopra i titoli di sezione.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = kMuted});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: TextStyle(
          fontSize: 11,
          letterSpacing: 2.2,
          fontWeight: FontWeight.w600,
          color: color));
}

/// Link sottolineato con freccia ("Vedi tutti i tour →").
class ArrowLink extends StatelessWidget {
  const ArrowLink(this.text, {super.key, required this.onTap});
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kInk,
                      decoration: TextDecoration.underline,
                      decorationColor: kInk)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 15, color: kInk),
            ],
          ),
        ),
      );
}

/// Pulsante oro con freccia, come "Cerca tour →".
class GoldButton extends StatelessWidget {
  const GoldButton(this.label,
      {super.key, required this.onPressed, this.expand = false});
  final String label;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: Size(expand ? double.infinity : 0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward, size: 17),
          ],
        ),
      );
}

/// Logo testuale con l'icona del monumento.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.light = true, this.tagline});
  final bool light;
  final String? tagline;

  @override
  Widget build(BuildContext context) {
    final fg = light ? Colors.white : kInk;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.account_balance_outlined, size: 34, color: kGold),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GUIDATOUR',
                style: TextStyle(
                    fontFamily: kSerif,
                    fontSize: 22,
                    height: 1,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                    color: fg)),
            if (tagline != null) ...[
              const SizedBox(height: 4),
              Text(tagline!.toUpperCase(),
                  style: TextStyle(
                      fontSize: 8.5,
                      letterSpacing: 1.6,
                      color: fg.withValues(alpha: 0.8))),
            ],
          ],
        ),
      ],
    );
  }
}

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
      {super.key,
      required this.title,
      this.eyebrow,
      this.subtitle,
      this.action,
      this.onAction});
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Eyebrow(eyebrow!),
                const SizedBox(height: 6),
              ],
              Text(title,
                  style: TextStyle(
                      fontFamily: kSerif,
                      fontSize: wide ? 26 : 20,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      color: kInk)),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!,
                    style: const TextStyle(fontSize: 15, color: kMuted)),
              ],
            ],
          ),
        ),
        if (action != null && wide) ...[
          const SizedBox(width: 16),
          ArrowLink(action!, onTap: onAction),
        ],
      ],
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid(
      {super.key, required this.children, this.itemHeight = 352});
  final List<Widget> children;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 1100
          ? 4
          : (c.maxWidth >= 820 ? 3 : (c.maxWidth >= 540 ? 2 : 1));
      const gap = 16.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children)
            SizedBox(
                width: w,
                // Su una colonna la card è più larga: serve meno altezza.
                height: cols == 1 ? itemHeight - 50 : itemHeight,
                child: child),
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

/// Una foto per categoria (Unsplash, in assets/images): i tour non hanno
/// ancora immagini proprie.
const _categoryImages = {
  'Visita guidata': 'assets/images/cat_visita.jpg',
  'Tour a piedi': 'assets/images/cat_piedi.jpg',
  'Enogastronomico': 'assets/images/cat_food.jpg',
  'Bambini e famiglie': 'assets/images/cat_famiglie.jpg',
  'Serale': 'assets/images/cat_serale.jpg',
  'Accompagnamento': 'assets/images/cat_accompagnamento.jpg',
};

/// Velo nero sulle foto per il tema scuro (circa un terzo di luce in meno).
const kPhotoShade = Color(0x52000000);

/// Le foto notturne sono già scure: niente velo.
Color? photoShade(String asset) =>
    asset.endsWith('cat_serale.jpg') ? null : kPhotoShade;

ColorFilter? photoFilter(String asset) {
  final shade = photoShade(asset);
  return shade == null ? null : ColorFilter.mode(shade, BlendMode.srcATop);
}

String categoryImage(String c) =>
    _categoryImages[c] ?? 'assets/images/cat_visita.jpg';

class TourCard extends StatelessWidget {
  const TourCard({super.key, required this.tour, required this.onTap});
  final Tour tour;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final guide = appState.guideById(tour.guideId);
    final user = appState.currentUser;
    final canFavorite = user != null && !user.role.isProfessional;
    final favorite = appState.isFavorite(tour.id);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 128,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'tour-color-${tour.id}',
                    child: Image.asset(categoryImage(tour.category),
                        fit: BoxFit.cover,
                        color: photoShade(categoryImage(tour.category)),
                        colorBlendMode: BlendMode.srcATop),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(categoryLabel(context, tour.category),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFC0392B))),
                    ),
                  ),
                  if (canFavorite)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: IconButton(
                        onPressed: () => runOrSnack(
                            context, () => appState.toggleFavorite(tour.id)),
                        icon: Icon(
                            favorite ? Icons.favorite : Icons.favorite_border,
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black45, blurRadius: 6)
                            ]),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event, size: 14, color: kPrimary),
                        const SizedBox(width: 5),
                        Text(fmtDate(tour.start),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kPrimary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(tour.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: kSerif,
                            fontSize: 19,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                            color: kInk)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                            child: _CardFact(Icons.schedule, tour.duration)),
                        Expanded(
                            child: _CardFact(Icons.translate,
                                languageLabel(context, tour.language))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (guide != null)
                      _CardFact(Icons.person_outline,
                          '${guide.name} · ${roleLabel(context, guide.role)}'),
                    const Spacer(),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 13, color: kInk),
                        children: [
                          TextSpan(text: '${t.tourFrom} '),
                          TextSpan(
                              text: fmtPrice(tour.price),
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700)),
                          TextSpan(text: '  ${t.tourPerPerson}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    GoldButton(t.tourDiscover, onPressed: onTap, expand: true),
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

class _CardFact extends StatelessWidget {
  const _CardFact(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 15, color: kMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, color: kMuted)),
          ),
        ],
      );
}

class InfoBanner extends StatelessWidget {
  const InfoBanner(this.text, {super.key, this.warning = false});
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning ? const Color(0xFFFFF1D6) : kSand;
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

/// Selettore della città in alto (fuori dal modulo di ricerca, perché vale
/// per tutta l'app): filtra i tour e cambia la foto di copertina. "Tutta
/// Italia" finché l'utente non sceglie.
class CityPicker extends StatelessWidget {
  const CityPicker({super.key});

  /// Valore della voce "Tutta Italia" nel menu (un null chiuderebbe il menu
  /// come un annullamento).
  static const _allItaly = '';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final t = l10n(context);
        final city = appState.city;
        return Material(
          color: kSurface,
          elevation: 1,
          borderRadius: BorderRadius.circular(20),
          child: PopupMenuButton<String>(
            tooltip: t.fieldCity,
            initialValue: city ?? _allItaly,
            onSelected: (c) => appState.setCity(c == _allItaly ? null : c),
            itemBuilder: (context) => [
              PopupMenuItem(value: _allItaly, child: Text(t.cityAllItaly)),
              const PopupMenuDivider(),
              for (final c in tourCities)
                PopupMenuItem(value: c, child: Text(cityLabel(context, c))),
            ],
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 18, color: kPrimary),
                  const SizedBox(width: 4),
                  Text(city == null ? t.cityAllItaly : cityLabel(context, city),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: kInk)),
                  const Icon(Icons.expand_more, size: 18, color: kMuted),
                ],
              ),
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
          color: kSurface,
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

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'l10n/labels.dart';
import 'l10n/locale_controller.dart';
import 'models.dart';
import 'legal_texts.dart';
import 'screens/faq_screen.dart';
import 'screens/legal_screen.dart';
import 'state.dart';

/// Oro scuro: icone grandi, riempimenti e accenti su fondo chiaro.
const kPrimary = Color(0xFFB4832F);

/// Oro bruno per testi, link e icone piccole su fondo chiaro: kPrimary come
/// testo non arriva al contrasto minimo (3:1), questo supera 4,5:1 anche sul
/// giallo delle pagine interne.
const kPrimaryText = Color(0xFF8A6020);

/// Oro chiaro dei pulsanti principali.
const kGold = Color(0xFFF2C36B);

/// Testo sopra i pulsanti oro.
const kOnGold = Color(0xFF1E2A33);

/// Oro dei titoli in corsivo sulle foto.
const kGoldText = Color(0xFFF0C878);
const kInk = Color(0xFF1E2A33);
/// Grigio dei testi secondari: almeno 5,5:1 anche sulla sabbia.
const kMuted = Color(0xFF5A5E65);

/// Sfondo delle pagine.
const kCream = Color(0xFFFBF7F0);

/// Card, riquadri e sezioni alternate.
const kSurface = Colors.white;
const kSand = Color(0xFFF6EEDF);

/// Sfondo delle pagine interne: giallo chiaro, le schede bianche risaltano.
const kPageYellow = Color(0xFFFCF1D4);

/// Fascia dorata delle intestazioni di pagina.
const kHeaderGradient = LinearGradient(
  colors: [Color(0xFFF2C36B), Color(0xFFF8DFA8)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
/// Bordi e divisori: visibili su bianco e crema, sempre caldi.
const kLine = Color(0xFFDCD0BA);

/// Bordo dei campi di testo e dei pulsanti outlined: almeno 3:1 sul bianco,
/// così si capisce dove scrivere.
const kFieldLine = Color(0xFF968669);

/// Blu notte di intestazione e footer.
const kNight = Color(0xFF1F2A33);

/// Font dei titoli (Playfair Display, vedi pubspec).
const kSerif = 'Playfair';

/// Larghezza massima del contenuto della home: tutte le sezioni stanno in
/// questa colonna, anche su schermi molto larghi.
const kContentWidth = 1320.0;

/// Da questa larghezza in su: menu in alto e sezioni affiancate. Sotto (telefoni
/// e tablet in verticale): barra in basso e sezioni in colonna.
const kDesktopWidth = 1024.0;

/// Raggio d'angolo condiviso da card e contenitori arrotondati.
const kRadius = 12.0;

/// Raggio di pulsanti, campi e riquadri piccoli.
const kRadiusSm = 10.0;

/// Raggio delle etichette "a pillola" (categorie, stati, selettori).
const kRadiusPill = 20.0;

/// Spaziature: sempre multipli di questa scala.
const kGapXs = 4.0;
const kGapSm = 8.0;
const kGapMd = 12.0;
const kGapLg = 16.0;
const kGapXl = 24.0;

/// Rosso mattone per azioni distruttive ed errori (intonato alla palette calda).
const kDanger = Color(0xFFA32A20);
const kDangerBg = Color(0xFFFBE3E1);

/// Verde per conferme ed esiti positivi.
const kSuccess = Color(0xFF1F6B3A);
const kSuccessBg = Color(0xFFDDF1E3);

/// Ombra morbida e calda di card e riquadri in rilievo.
List<BoxShadow> kSoftShadow([double lift = 0]) => [
      BoxShadow(
        color: const Color(0xFF6B4A12).withValues(alpha: 0.08 + lift * 0.04),
        blurRadius: 18 + lift * 10,
        offset: Offset(0, 6 + lift * 4),
      ),
      BoxShadow(
        color: kInk.withValues(alpha: 0.04),
        blurRadius: 3,
        offset: const Offset(0, 1),
      ),
    ];

/// Scala tipografica dell'app: titoli in Playfair, il resto in Inter.
/// Le schermate usano questi stili invece di dimensioni scritte a mano.
const kTextTheme = TextTheme(
  displaySmall: TextStyle(
      fontFamily: kSerif,
      fontSize: 30,
      height: 1.15,
      fontWeight: FontWeight.w700,
      color: kInk),
  headlineSmall: TextStyle(
      fontFamily: kSerif,
      fontSize: 24,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: kInk),
  titleLarge: TextStyle(
      fontFamily: kSerif,
      fontSize: 20,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: kInk),
  titleMedium:
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kInk),
  titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kInk),
  bodyLarge: TextStyle(fontSize: 15, height: 1.45, color: kInk),
  bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: kInk),
  bodySmall: TextStyle(fontSize: 12, height: 1.4, color: kMuted),
  labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  labelSmall:
      TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3),
);

/// Aggiunge la scala tipografica a un tema già costruito. Va fatto dopo:
/// `ThemeData(fontFamily: ...)` imporrebbe Inter anche ai titoli in Playfair.
ThemeData withAppText(ThemeData base) =>
    base.copyWith(textTheme: base.textTheme.merge(kTextTheme));

/// Colore d'accento per ogni categoria: tutti della stessa famiglia calda,
/// per riconoscere le categorie a colpo d'occhio sulle card.
const _categoryColors = {
  'Visita guidata': Color(0xFF9A6B1F),
  'Tour a piedi': Color(0xFF5E7A3A),
  'Enogastronomico': Color(0xFFA34A2A),
  'Bambini e famiglie': Color(0xFF2F6F7A),
  'Serale': Color(0xFF3E4A7A),
  'Accompagnamento': Color(0xFF7A4A6B),
};

Color categoryColor(String c) => _categoryColors[c] ?? kPrimary;

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
                      fontSize: 9,
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
/// Azioni della struttura principale, per le pagine e per il footer: tornare
/// a Scopri e aprire una pagina sotto intestazione e footer.
class ShellScope extends InheritedWidget {
  const ShellScope({
    super.key,
    required this.goHome,
    required this.open,
    required this.root,
    this.openSearch,
    this.rememberSearch,
    required super.child,
  });

  /// La pagina Tour comunica ricerca e filtri correnti, per ritrovarli
  /// tornando con "indietro" da un'altra voce.
  final void Function(String query, String? category, String? language)?
      rememberSearch;
  final VoidCallback goHome;

  /// Apre una pagina sotto intestazione e footer. Con [name] non apre doppioni:
  /// se è già aperta si torna a quella.
  final void Function(Widget page, {String? name}) open;

  /// Passa alla voce "Tour" con ricerca e categoria già impostate.
  final void Function({String query, String? category})? openSearch;

  /// Pagina della voce di menu scelta.
  final Widget root;

  static ShellScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope oldWidget) => root != oldWidget.root;
}

/// Contenuto di una pagina: titolo facoltativo, larghezza massima e il footer
/// in fondo (anche quando il contenuto è corto).
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.child,
    this.maxWidth = 1240,
    this.title,
    this.subtitle,
    this.icon,
  });
  final Widget child;
  final double maxWidth;

  /// Con il titolo la pagina apre con l'intestazione dorata.
  final String? title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= kDesktopWidth;
    // Material e non ColoredBox: caselle e voci di elenco disegnano l'effetto
    // al tocco sulla superficie.
    return Material(
      color: kPageYellow,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding:
                EdgeInsets.fromLTRB(wide ? 48 : 20, 26, wide ? 48 : 20, 40),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: title == null
                      ? child
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PageHeader(
                                title: title!,
                                icon: icon ?? Icons.article_outlined,
                                subtitle: subtitle),
                            const SizedBox(height: 18),
                            child,
                          ],
                        ),
                ),
              ),
            ),
          ),
          // Il footer sta in fondo allo schermo se la pagina è corta, altrimenti
          // dopo il contenuto. Calcolato sullo spazio libero, non sui testi.
          SliverLayoutBuilder(
            builder: (context, c) => SliverToBoxAdapter(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minHeight: math.max(
                        0, c.viewportMainAxisExtent - c.precedingScrollExtent)),
                child: const Align(
                    alignment: Alignment.bottomCenter, child: SiteFooter()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Intestazione di pagina: fascia dorata con icona, titolo e una riga che
/// spiega a cosa serve la pagina.
class PageHeader extends StatelessWidget {
  const PageHeader(
      {super.key, required this.title, required this.icon, this.subtitle});
  final String title;
  final IconData icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(narrow ? 16 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kRadius),
        gradient: kHeaderGradient,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(narrow ? 9 : 12),
            decoration:
                const BoxDecoration(color: kNight, shape: BoxShape.circle),
            child: Icon(icon, color: kGold, size: narrow ? 22 : 28),
          ),
          SizedBox(width: narrow ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontFamily: kSerif,
                        fontSize: narrow ? 22 : 26,
                        fontWeight: FontWeight.w700,
                        color: kInk)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!,
                      style: const TextStyle(color: kInk, height: 1.35)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Footer di tutte le pagine: marchio (porta a Scopri), FAQ e avvertenza.
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final shell = ShellScope.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 700;
    const heading = TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white);
    final brand = InkWell(
      key: const ValueKey('footer-brand'),
      onTap: shell?.goHome,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: BrandLogo(tagline: t.footerTagline),
      ),
    );
    final disclaimer = Text(t.platformDisclaimer,
        style:
            const TextStyle(fontSize: 12, height: 1.5, color: Colors.white54));
    final links = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.footerLinks, style: heading),
        const SizedBox(height: 10),
        for (final (key, label, open) in [
          (
            'footer-faq',
            t.faqTitle,
            () => shell?.open(const FaqScreen(), name: 'faq')
          ),
          (
            'footer-privacy',
            t.footerPrivacy,
            () => openLegal(context, LegalKind.privacy)
          ),
          (
            'footer-terms',
            t.footerTerms,
            () => openLegal(context, LegalKind.terms)
          ),
        ])
          InkWell(
            key: ValueKey(key),
            onTap: open,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: Colors.white70)),
            ),
          ),
      ],
    );
    return Container(
      width: double.infinity,
      color: kNight,
      padding: EdgeInsets.fromLTRB(
          wide ? 48 : 20, wide ? 16 : 22, wide ? 48 : 20, wide ? 14 : 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Su schermo largo una fascia sola: marchio, avvertenza accanto
              // e link utili in fondo a destra.
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    brand,
                    const SizedBox(width: 36),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: disclaimer,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 36),
                    links,
                  ],
                )
              else ...[
                brand,
                const SizedBox(height: 12),
                disclaimer,
                const SizedBox(height: 14),
                links,
              ],
              SizedBox(height: wide ? 10 : 14),
              const Divider(color: Colors.white12, height: 1),
              SizedBox(height: wide ? 10 : 12),
              Text('© ${DateTime.now().year} guidatour. ${t.footerRights}',
                  style: const TextStyle(fontSize: 12, color: Colors.white54)),
            ],
          ),
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
    final wide = MediaQuery.of(context).size.width >= kDesktopWidth;
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

const _cardPhotoHeight = 120.0;

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid(
      {super.key, required this.children, this.itemHeight = 356});
  final List<Widget> children;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 1100
          ? 4
          : (c.maxWidth >= 820 ? 3 : (c.maxWidth >= 540 ? 2 : 1));
      const gap = 14.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      // Il testo cresce con il carattere impostato sul telefono, la foto no.
      final height = _cardPhotoHeight +
          MediaQuery.textScalerOf(context).scale(itemHeight - _cardPhotoHeight);
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final (i, child) in children.indexed)
            SizedBox(
                width: w,
                height: height,
                child: FadeSlideIn(index: i, child: child)),
        ],
      );
    });
  }
}

/// Comparsa morbida dal basso, una card dopo l'altra (indice = ritardo).
/// Ritardo con un Interval e non con un timer: nei test non restano timer
/// in sospeso e l'elemento è subito presente e toccabile.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  static const _step = 70; // ms tra una card e la successiva
  static const _run = 380; // ms di ogni comparsa

  late final int _delay = math.min(widget.index, 8) * _step;
  late final _c = AnimationController(
      vsync: this, duration: Duration(milliseconds: _delay + _run))
    ..forward();
  late final _anim = CurvedAnimation(
      parent: _c,
      curve: Interval(_delay / (_delay + _run), 1, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.06), end: Offset.zero)
              .animate(_anim),
          child: widget.child,
        ),
      );
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


/// Velo nero sulle foto (40% di luce in meno): i titoli chiari restano
/// leggibili anche sulle foto luminose.
const kPhotoShade = Color(0x66000000);

/// Ombra dei testi piccoli sopra le foto: li stacca dalle zone luminose.
const kTextOnPhotoShadow = [Shadow(color: Color(0x99000000), blurRadius: 6)];

/// Le foto notturne sono già scure: niente velo.
Color? photoShade(String asset) =>
    asset.contains('cat_serale') ? null : kPhotoShade;

/// Foto di ogni categoria con la città che vi si riconosce (null = nessuna
/// città riconoscibile). Un tour mostra solo foto della sua città o neutre:
/// mai il Colosseo per un tour di Milano. Crediti in assets/CREDITI_FOTO.txt.
const _categoryPhotos = <String, List<(String, String?)>>{
  'Visita guidata': [
    ('cat_visita.jpg', 'Roma'),
    ('cat_visita_2.jpg', 'Firenze'),
    ('cat_visita_3.jpg', 'Roma'),
    ('cat_visita_4.jpg', 'Venezia'),
    ('cat_visita_5.jpg', null),
    ('cat_visita_6.jpg', null),
  ],
  'Tour a piedi': [
    ('cat_piedi.jpg', null),
    ('cat_piedi_2.jpg', 'Venezia'),
    ('cat_piedi_3.jpg', null),
    ('cat_piedi_4.jpg', null),
  ],
  'Enogastronomico': [
    ('cat_food.jpg', null),
    ('cat_food_2.jpg', null),
    ('cat_food_3.jpg', null),
    ('cat_food_4.jpg', null),
  ],
  'Bambini e famiglie': [
    ('cat_famiglie.jpg', null),
    ('cat_famiglie_2.jpg', null),
    ('cat_famiglie_3.jpg', null),
    ('cat_famiglie_4.jpg', null),
  ],
  'Serale': [
    ('cat_serale.jpg', 'Roma'),
    ('cat_serale_2.jpg', 'Firenze'),
    ('cat_serale_3.jpg', 'Venezia'),
    ('cat_serale_4.jpg', 'Firenze'),
    ('cat_serale_5.jpg', null),
    ('cat_serale_6.jpg', null),
  ],
  'Accompagnamento': [
    ('cat_accompagnamento.jpg', null),
    ('cat_accompagnamento_2.jpg', null),
    ('cat_accompagnamento_3.jpg', null),
    ('cat_accompagnamento_4.jpg', null),
  ],
};

List<(String, String?)> _photosOf(String category) =>
    _categoryPhotos[category] ?? _categoryPhotos['Visita guidata']!;

/// Tutte le foto delle categorie con la loro città (per i test).
Iterable<(String, String?)> get allCategoryPhotos => _categoryPhotos.values
    .expand((l) => l)
    .map((p) => ('assets/images/${p.$1}', p.$2));

/// Foto di un tour: della sua città o neutra, sempre la stessa per lo stesso
/// tour ma diversa tra tour vicini. Somma dei caratteri dell'id e non
/// hashCode, che cambia tra web e telefono.
String tourImage(Tour tour) {
  final pool = [
    for (final (file, city) in _photosOf(tour.category))
      if (city == null || city == tour.city) file,
  ];
  final n = tour.id.codeUnits.fold<int>(0, (a, c) => a * 31 + c & 0x7fffffff) %
      pool.length;
  return 'assets/images/${pool[n]}';
}

/// Foto che rappresenta una categoria (cerchi in home). Con una città
/// scelta: una foto di quella città se c'è, altrimenti una neutra; per tutta
/// Italia la prima, la più riconoscibile.
String categoryImage(String c, {String? city}) {
  final photos = _photosOf(c);
  final file = city == null
      ? photos.first.$1
      : (photos.where((p) => p.$2 == city).firstOrNull ??
              photos.firstWhere((p) => p.$2 == null))
          .$1;
  return 'assets/images/$file';
}

ColorFilter? photoFilter(String asset) {
  final shade = photoShade(asset);
  return shade == null ? null : ColorFilter.mode(shade, BlendMode.srcATop);
}


class TourCard extends StatefulWidget {
  const TourCard({super.key, required this.tour, required this.onTap});
  final Tour tour;
  final VoidCallback onTap;

  @override
  State<TourCard> createState() => _TourCardState();
}

class _TourCardState extends State<TourCard> {
  /// Mouse sopra la card (web/desktop): si alza e la foto si avvicina.
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tour = widget.tour;
    final onTap = widget.onTap;
    final t = l10n(context);
    final guide = appState.guideById(tour.guideId);
    final user = appState.currentUser;
    final canFavorite = user != null && !user.role.isProfessional;
    final favorite = appState.isFavorite(tour.id);
    final accent = categoryColor(tour.category);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kRadius),
          boxShadow: kSoftShadow(_hover ? 1 : 0),
        ),
        child: Material(
          color: kSurface,
          // Bordo sottile oltre all'ombra: la card si stacca anche dagli
          // sfondi chiari (bianco su crema da solo ha contrasto 1,07).
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadius),
            side: BorderSide(color: _hover ? kFieldLine : kLine),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: _cardPhotoHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'tour-color-${tour.id}',
                        child: AnimatedScale(
                          scale: _hover ? 1.05 : 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          child: Image.asset(tourImage(tour),
                              fit: BoxFit.cover,
                              color: photoShade(tourImage(tour)),
                              colorBlendMode: BlendMode.srcATop),
                        ),
                      ),
                      // Sfumatura scura in basso: profondità e stacco dal testo.
                      const IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.45, 1],
                              colors: [Color(0x00000000), Color(0x80000000)],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: kGapXs),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(kRadiusPill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(categoryIcon(tour.category),
                                  size: 13, color: accent),
                              const SizedBox(width: 5),
                              Text(categoryLabel(context, tour.category),
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: accent)),
                            ],
                          ),
                        ),
                      ),
                      if (canFavorite)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: IconButton(
                            onPressed: () => runOrSnack(context,
                                () => appState.toggleFavorite(tour.id)),
                            icon: Icon(
                                favorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(color: Colors.black45, blurRadius: 6)
                                ]),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(height: 3, color: accent.withValues(alpha: 0.85)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, kGapMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event, size: 14, color: kPrimaryText),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(tourDatesLabel(context, tour),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: kPrimaryText)),
                            ),
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
                                child:
                                    _CardFact(Icons.schedule, tour.duration)),
                            Expanded(
                                child: _CardFact(Icons.translate,
                                    languageLabel(context, tour.language))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (guide != null)
                          // Pallino con foto o iniziali: più calore e fiducia
                          // di un'icona generica.
                          Row(
                            children: [
                              UserAvatar(user: guide, radius: 11),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                    '${guide.name} · ${rolesLabel(context, guide.roles)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12, color: kMuted)),
                              ),
                            ],
                          ),
                        const Spacer(),
                        Text.rich(
                          TextSpan(
                            style: const TextStyle(fontSize: 12, color: kMuted),
                            children: [
                              TextSpan(text: '${t.tourFrom} '),
                              TextSpan(
                                  text: fmtPrice(tour.price),
                                  // Inter: le cifre in Playfair si leggono male.
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                      color: kInk)),
                              TextSpan(text: '  ${t.tourPerPerson}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        GoldButton(t.tourDiscover,
                            onPressed: onTap, expand: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                style: const TextStyle(fontSize: 12, color: kMuted)),
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
    final fg = warning ? const Color(0xFF7A4B00) : kPrimaryText;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(kRadiusSm),
        border: Border.all(color: fg.withValues(alpha: 0.18)),
      ),
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

enum PillTone { waiting, ok, alert }

/// Etichetta arrotondata per gli stati (in attesa, confermata, rifiutata...).
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.tone = PillTone.waiting});
  final String label;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      PillTone.ok => (kSuccessBg, kSuccess),
      PillTone.alert => (kDangerBg, kDanger),
      PillTone.waiting => (const Color(0xFFF8E3B5), kOnGold),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: kGapXs),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(kRadiusPill)),
      child: Text(label,
          style:
              TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

/// Riquadro bianco con titolo e icona su cerchio dorato, bordo dorato in alto.
class GoldPanel extends StatelessWidget {
  const GoldPanel(
      {super.key,
      required this.title,
      required this.icon,
      required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  // Material e non un Container colorato: le voci al tocco (ListTile) devono
  // poter disegnare l'effetto sulla superficie.
  Widget build(BuildContext context) => Material(
        color: kSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
          side: const BorderSide(color: kLine),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 4, color: kGold),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                            color: kGold.withValues(alpha: 0.3),
                            shape: BoxShape.circle),
                        child: Icon(icon, size: 18, color: kPrimaryText),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(title,
                            style: const TextStyle(
                                fontFamily: kSerif,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: kInk)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  child,
                ],
              ),
            ),
          ],
        ),
      );
}

/// Stato vuoto curato (icona + messaggio) al posto di un semplice testo.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: kGapLg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Doppio cerchio dorato: più "illustrazione" di una sola icona.
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: kGold.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: kGold.withValues(alpha: 0.28),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 34, color: kPrimary),
                ),
              ),
              const SizedBox(height: kGapLg),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: kSerif,
                      fontSize: 19,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: kInk)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Segnaposto che pulsa mentre i dati arrivano (il primo avvio su Render può
/// essere lento): fa intuire la forma del contenuto meglio di una rotellina.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox(
      {super.key, this.width, this.height = 14, this.radius = kRadiusSm});
  final double? width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 0.45, end: 1.0)
            .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: kLine,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      );
}

/// Elenco segnaposto (righe con avatar e due linee di testo) per le liste in
/// caricamento.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.rows = 4});
  final int rows;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: kGapLg),
        child: Column(
          children: [
            for (var i = 0; i < rows; i++)
              Container(
                margin: const EdgeInsets.only(bottom: kGapMd),
                padding: const EdgeInsets.all(kGapLg),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(kRadius),
                  border: Border.all(color: kLine),
                ),
                child: Row(
                  children: [
                    const SkeletonBox(width: 40, height: 40, radius: 20),
                    const SizedBox(width: kGapMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FractionallySizedBox(
                              widthFactor: i.isEven ? 0.55 : 0.4,
                              child: const SkeletonBox(height: 14)),
                          const SizedBox(height: kGapSm),
                          FractionallySizedBox(
                              widthFactor: i.isEven ? 0.8 : 0.7,
                              child: const SkeletonBox(height: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
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
          borderRadius: BorderRadius.circular(kRadiusPill),
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
                  const Icon(Icons.location_on, size: 18, color: kPrimaryText),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                        city == null
                            ? t.cityAllItaly
                            : cityLabel(context, city),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: kInk)),
                  ),
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
          borderRadius: BorderRadius.circular(kRadiusPill),
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
                  const Icon(Icons.language, size: 18, color: kPrimaryText),
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

/// Pallino dell'utente: la foto o, se manca o non si carica, le iniziali.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.radius = 19});
  final Guide user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = user.avatarUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: kGold,
      foregroundColor: kOnGold,
      foregroundImage: url == null ? null : NetworkImage(url),
      onForegroundImageError: url == null ? null : (_, __) {},
      child: Text(user.initials,
          style:
              TextStyle(fontSize: radius * 0.8, fontWeight: FontWeight.w700)),
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

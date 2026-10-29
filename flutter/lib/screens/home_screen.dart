import 'package:flutter/material.dart';

import '../l10n/labels.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'search_screen.dart';
import 'tour_detail_screen.dart';
import 'whatsapp_optin.dart';

/// Foto di copertina per città (Unsplash, in assets/images).
const _cityHeroes = {
  'Roma': 'assets/images/hero_roma.jpg',
  'Firenze': 'assets/images/hero_firenze.jpg',
  'Venezia': 'assets/images/hero_venezia.jpg',
  'Milano': 'assets/images/hero_milano.jpg',
  'Napoli': 'assets/images/hero_napoli.jpg',
  'Bologna': 'assets/images/hero_bologna.jpg',
  'Torino': 'assets/images/hero_torino.jpg',
};

String _heroFor(String city) =>
    _cityHeroes[city] ?? 'assets/images/hero_italia.jpg';

void _openSearch(BuildContext context, {String query = '', String? category}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(),
        body: SearchScreen(initialQuery: query, initialCategory: category),
      ),
    ),
  );
}

/// Home a sezioni a tutta larghezza: copertina con ricerca, tour in partenza,
/// categorie, banner per i professionisti, guide, WhatsApp, invito finale e
/// footer.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.header,
    required this.links,
    required this.onOpenSearch,
    required this.onOpenAccount,
  });

  /// Barra di navigazione sovrapposta alla foto di copertina.
  final Widget header;

  /// Voci del menu ripetute nel footer.
  final List<(String, VoidCallback)> links;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenAccount;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();

  /// Prima sezione sotto la copertina: la freccia "scorri giù" porta qui.
  final _toursKey = GlobalKey();

  Widget get header => widget.header;
  List<(String, VoidCallback)> get links => widget.links;
  VoidCallback get onOpenSearch => widget.onOpenSearch;
  VoidCallback get onOpenAccount => widget.onOpenAccount;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    final target = _toursKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(target,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final wide = MediaQuery.of(context).size.width >= 900;
        final user = appState.currentUser;
        return Scrollbar(
          controller: _scroll,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scroll,
            child: Column(
              children: [
                _Hero(header: header, wide: wide, onScrollDown: _scrollDown),
                KeyedSubtree(
                    key: _toursKey,
                    child: _Section(
                        color: Colors.white, child: _tours(context, wide))),
                _Section(color: kCream, child: _categories(context, wide)),
                if (user == null || !user.role.isProfessional)
                  _ProSection(wide: wide, onStart: onOpenAccount),
                if (appState.guides.isNotEmpty)
                  _Section(color: Colors.white, child: _guides(context, wide)),
                const _Section(
                    color: kCream, child: WhatsAppOptInCard(source: 'Home')),
                _CtaBand(wide: wide, onBook: onOpenSearch),
                _Footer(wide: wide, links: links),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tours(BuildContext context, bool wide) {
    final t = l10n(context);
    final city = cityLabel(context, appState.city);
    final upcoming = [...appState.tours]
      ..sort((a, b) => a.start.compareTo(b.start));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(
          title: t.toursTitle(city),
          action: t.toursAction,
          onAction: onOpenSearch,
        ),
        const SizedBox(height: 16),
        if (upcoming.isEmpty)
          EmptyState(icon: Icons.explore_outlined, message: t.searchNoResults)
        else
          ResponsiveGrid(children: [
            for (final tour in upcoming.take(4))
              TourCard(tour: tour, onTap: () => openTour(context, tour)),
          ]),
        if (!wide) ...[
          const SizedBox(height: 12),
          ArrowLink(t.toursAction, onTap: onOpenSearch),
        ],
      ],
    );
  }

  Widget _categories(BuildContext context, bool wide) {
    final t = l10n(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(
          title: t.categoriesTitle,
          action: t.categoriesAction,
          onAction: onOpenSearch,
        ),
        const SizedBox(height: 16),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final c in tourCategories)
                Expanded(child: _CategoryBubble(category: c, size: 96)),
            ],
          )
        else
          SizedBox(
            height: 124,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tourCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) => SizedBox(
                  width: 124,
                  child:
                      _CategoryBubble(category: tourCategories[i], size: 72)),
            ),
          ),
      ],
    );
  }

  Widget _guides(BuildContext context, bool wide) {
    final t = l10n(context);
    final local =
        appState.guides.where((g) => g.city == appState.city).toList();
    final guides = (local.isEmpty ? appState.guides : local).take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(title: t.guidesTitle),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth >= 820 ? 3 : 1;
          const gap = 20.0;
          final w = (c.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final g in guides) SizedBox(width: w, child: _GuideCard(g)),
            ],
          );
        }),
      ],
    );
  }
}

/// Fascia a tutta larghezza con il contenuto centrato.
class _Section extends StatelessWidget {
  const _Section({required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    return Container(
      width: double.infinity,
      color: color,
      padding: EdgeInsets.symmetric(
          horizontal: wide ? 48 : 20, vertical: wide ? 28 : 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: child,
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero(
      {required this.header, required this.wide, required this.onScrollDown});
  final Widget header;
  final bool wide;
  final VoidCallback onScrollDown;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kNight,
        image: DecorationImage(
          image: AssetImage(_heroFor(appState.city)),
          fit: BoxFit.cover,
          alignment: const Alignment(0.4, 0),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.black.withValues(alpha: 0.78),
              Colors.black.withValues(alpha: 0.4),
              Colors.black.withValues(alpha: 0.1),
            ],
            stops: const [0, 0.55, 1],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
              child: header,
            ),
            Stack(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      wide ? 48 : 20, wide ? 16 : 10, wide ? 48 : 20, 0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1240),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(t.homeHeroLine1,
                              style: TextStyle(
                                  fontFamily: kSerif,
                                  fontSize: wide ? 46 : 30,
                                  height: 1.05,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          Text(t.homeHeroLine2,
                              style: TextStyle(
                                  fontFamily: kSerif,
                                  fontSize: wide ? 38 : 24,
                                  height: 1.15,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                  color: kGoldText)),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 480),
                              child: Text(t.homeHeroSubtitle,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.4,
                                      color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 880),
                              child: _HeroSearchPanel(wide: wide),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 32,
                            runSpacing: 16,
                            children: [
                              _TrustItem(Icons.verified_outlined,
                                  t.trustGuidesTitle, t.trustGuidesBody),
                              _TrustItem(Icons.mail_outline,
                                  t.trustRequestTitle, t.trustRequestBody),
                              _TrustItem(Icons.check_circle_outline,
                                  t.trustConfirmTitle, t.trustConfirmBody),
                              _TrustItem(Icons.chat_bubble_outline,
                                  t.trustWhatsappTitle, t.trustWhatsappBody),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (MediaQuery.of(context).size.width >= 1300)
                  Positioned(
                    right: 70,
                    top: 60,
                    child: Transform.rotate(
                      angle: -0.2,
                      child: SizedBox(
                        width: 240,
                        child: Text(t.homeHeroScript,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontFamily: 'Caveat',
                                fontSize: 34,
                                height: 1.05,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 8)
                                ])),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6, top: 4),
              child: IconButton(
                onPressed: onScrollDown,
                style: IconButton.styleFrom(
                  side: const BorderSide(color: Colors.white70),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.keyboard_arrow_down, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Riquadro bianco di ricerca: città, tipo di tour, testo libero.
class _HeroSearchPanel extends StatefulWidget {
  const _HeroSearchPanel({required this.wide});
  final bool wide;

  @override
  State<_HeroSearchPanel> createState() => _HeroSearchPanelState();
}

class _HeroSearchPanelState extends State<_HeroSearchPanel> {
  final _controller = TextEditingController();
  String? _category;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go() =>
      _openSearch(context, query: _controller.text.trim(), category: _category);

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    const valueStyle =
        TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: kInk);
    final city = _PanelField(
        icon: Icons.location_on_outlined,
        label: t.fieldCity,
        child: const CityPicker(plain: true));
    final type = _PanelField(
      icon: Icons.tour_outlined,
      label: t.heroTourType,
      child: PopupMenuButton<String?>(
        tooltip: t.heroTourType,
        onSelected: (c) => setState(() => _category = c),
        itemBuilder: (context) => [
          PopupMenuItem(value: null, child: Text(t.heroAllTours)),
          for (final c in tourCategories)
            PopupMenuItem(value: c, child: Text(categoryLabel(context, c))),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                  _category == null
                      ? t.heroAllTours
                      : categoryLabel(context, _category!),
                  overflow: TextOverflow.ellipsis,
                  style: valueStyle),
            ),
            const Icon(Icons.expand_more, size: 18, color: kMuted),
          ],
        ),
      ),
    );
    final query = _PanelField(
      icon: Icons.search,
      label: t.heroWhat,
      child: TextField(
        controller: _controller,
        onSubmitted: (_) => _go(),
        style: valueStyle,
        decoration: InputDecoration.collapsed(
            hintText: t.searchHint,
            hintStyle: valueStyle.copyWith(
                color: kMuted, fontWeight: FontWeight.w400)),
      ),
    );
    final button =
        GoldButton(t.heroSearch, onPressed: _go, expand: !widget.wide);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 24)
        ],
      ),
      child: widget.wide
          ? Row(
              children: [
                city,
                const _PanelDivider(),
                SizedBox(width: 190, child: type),
                const _PanelDivider(),
                Expanded(child: query),
                const SizedBox(width: 10),
                button,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(child: city),
                  const _PanelDivider(),
                  Expanded(child: type),
                ]),
                const Divider(height: 12, color: kLine),
                query,
                const SizedBox(height: 10),
                button,
              ],
            ),
    );
  }
}

class _PanelField extends StatelessWidget {
  const _PanelField(
      {required this.icon, required this.label, required this.child});
  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: kMuted),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 11, color: kMuted)),
                  const SizedBox(height: 3),
                  child,
                ],
              ),
            ),
          ],
        ),
      );
}

class _PanelDivider extends StatelessWidget {
  const _PanelDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: kLine);
}

class _TrustItem extends StatelessWidget {
  const _TrustItem(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kGold, width: 1.5),
            ),
            child: Icon(icon, size: 18, color: kGold),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              Text(body,
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ],
      );
}

class _CategoryBubble extends StatelessWidget {
  const _CategoryBubble({required this.category, required this.size});
  final String category;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(kRadius),
      onTap: () => _openSearch(context, category: category),
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                    color: kInk.withValues(alpha: 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 4)),
              ],
              image: DecorationImage(
                  image: AssetImage(categoryImage(category)),
                  fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 12),
          Text(categoryLabel(context, category),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: kSerif,
                  fontSize: size < 120 ? 14 : 16,
                  fontWeight: FontWeight.w700,
                  color: kInk)),
        ],
      ),
    );
  }
}

/// "Sei una guida o un operatore?": foto a sinistra, testo e vantaggi a destra.
class _ProSection extends StatelessWidget {
  const _ProSection({required this.wide, required this.onStart});
  final bool wide;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(t.operatorBannerTitle,
            style: TextStyle(
                fontFamily: kSerif,
                fontSize: wide ? 26 : 22,
                height: 1.15,
                fontWeight: FontWeight.w700,
                color: kInk)),
        const SizedBox(height: 12),
        Text(t.operatorBannerBody,
            style: const TextStyle(fontSize: 15, height: 1.5, color: kMuted)),
        const SizedBox(height: 16),
        GoldButton(t.proButton, onPressed: onStart),
      ],
    );
    final features = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Feature(Icons.public, t.proFeaturePage),
        _Feature(Icons.qr_code_2, t.proFeatureQr),
        _Feature(Icons.inbox_outlined, t.proFeatureRequests),
        _Feature(Icons.swap_horiz, t.proFeatureAssign),
      ],
    );
    const image =
        Image(image: AssetImage('assets/images/pro.jpg'), fit: BoxFit.cover);
    if (!wide) {
      return Container(
        color: const Color(0xFFFDFAF5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 140, child: image),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [text, const SizedBox(height: 12), features],
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      color: const Color(0xFFFDFAF5),
      height: 280,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(flex: 5, child: image),
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Row(
                children: [
                  Expanded(child: text),
                  const SizedBox(width: 40),
                  Flexible(child: features),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration:
                  const BoxDecoration(color: kSand, shape: BoxShape.circle),
              child: Icon(icon, size: 19, color: kPrimary),
            ),
            const SizedBox(width: 14),
            Flexible(
                child: Text(text,
                    style: const TextStyle(fontSize: 14, color: kInk))),
          ],
        ),
      );
}

class _GuideCard extends StatelessWidget {
  const _GuideCard(this.guide);
  final Guide guide;

  @override
  Widget build(BuildContext context) {
    final initials = guide.name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kLine),
        boxShadow: [
          BoxShadow(
              color: kInk.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: kSand,
            child: Text(initials,
                style: const TextStyle(
                    fontFamily: kSerif,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: kPrimary)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(guide.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: kSerif,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: kInk)),
                    ),
                    if (guide.verified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, size: 16, color: kPrimary),
                    ],
                  ],
                ),
                Text(roleLabel(context, guide.role),
                    style: const TextStyle(fontSize: 12, color: kMuted)),
                if (guide.bio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(guide.bio,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, height: 1.4, color: kInk)),
                ],
                const SizedBox(height: 8),
                Text(
                    guide.languages
                        .map((l) => languageLabel(context, l))
                        .join(' · '),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Invito finale su foto panoramica.
class _CtaBand extends StatelessWidget {
  const _CtaBand({required this.wide, required this.onBook});
  final bool wide;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.ctaTitle,
            style: TextStyle(
                fontFamily: kSerif,
                fontSize: wide ? 32 : 24,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Text(t.ctaBody,
              style: const TextStyle(
                  fontSize: 16, height: 1.4, color: Colors.white)),
        ),
      ],
    );
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: kNight,
        image: DecorationImage(
          image: AssetImage('assets/images/cta.jpg'),
          fit: BoxFit.cover,
          alignment: Alignment(0, 0.1),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.black.withValues(alpha: 0.25),
            ],
          ),
        ),
        padding: EdgeInsets.symmetric(
            horizontal: wide ? 48 : 20, vertical: wide ? 28 : 22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: wide
                ? Row(
                    children: [
                      Expanded(child: text),
                      GoldButton(t.ctaButton, onPressed: onBook),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      text,
                      const SizedBox(height: 12),
                      GoldButton(t.ctaButton, onPressed: onBook),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.wide, required this.links});
  final bool wide;
  final List<(String, VoidCallback)> links;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    const heading = TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white);
    final brand = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandLogo(tagline: t.footerTagline),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Text(t.platformDisclaimer,
              style: const TextStyle(
                  fontSize: 12, height: 1.5, color: Colors.white54)),
        ),
      ],
    );
    final nav = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.footerLinks, style: heading),
        const SizedBox(height: 10),
        for (final (label, onTap) in links)
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: Colors.white70)),
            ),
          ),
      ],
    );
    final language = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.footerLanguage, style: heading),
        const SizedBox(height: 12),
        const LanguagePicker(),
      ],
    );
    return Container(
      width: double.infinity,
      color: kNight,
      padding: EdgeInsets.fromLTRB(wide ? 48 : 20, 28, wide ? 48 : 20, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: brand),
                    Expanded(flex: 2, child: nav),
                    Expanded(flex: 2, child: language),
                  ],
                )
              else ...[
                brand,
                const SizedBox(height: 18),
                nav,
                const SizedBox(height: 16),
                language,
              ],
              const SizedBox(height: 18),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 12),
              Text('© ${DateTime.now().year} guidatour. ${t.footerRights}',
                  style: const TextStyle(fontSize: 12, color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }
}

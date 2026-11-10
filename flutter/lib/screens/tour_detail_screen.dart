import 'package:flutter/material.dart';

import '../l10n/labels.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import '../legal_texts.dart';
import 'legal_screen.dart';
import 'tour_map.dart';
import 'whatsapp_optin.dart';

/// [fromList]: aperto dall'elenco dei tour; il link in alto dice "Torna ai
/// tour" e riporta all'elenco con ricerca e filtri com'erano.
void openTour(BuildContext context, Tour t,
    {bool fromQr = false, DateTime? date, bool fromList = false}) {
  if (fromQr) {
    // Il conteggio non deve fermare chi ha appena inquadrato il QR.
    appState.recordScan(t).catchError((_) {});
  } else {
    appState.recordVisit(t);
  }
  Navigator.of(context).push(
    MaterialPageRoute(
        builder: (_) =>
            TourDetailScreen(tour: t, initialDate: date, fromList: fromList)),
  );
}

class TourDetailScreen extends StatefulWidget {
  const TourDetailScreen(
      {super.key, required this.tour, this.initialDate, this.fromList = false});
  final Tour tour;

  /// Aperto dall'elenco dei tour (vedi [openTour]).
  final bool fromList;

  /// Data proposta (es. dal link di una pagina pubblica), se è tra le prossime.
  final DateTime? initialDate;

  @override
  State<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends State<TourDetailScreen> {
  Tour get tour => widget.tour;

  /// Data scelta per carrello e richiesta: di default la prossima uscita.
  late DateTime? _date = () {
    final up = tour.upcoming;
    final wanted = widget.initialDate;
    if (wanted != null && up.any((d) => d.isAtSameMomentAs(wanted))) {
      return wanted;
    }
    return up.isEmpty ? null : up.first;
  }();

  /// Modulo di richiesta: la barra in basso ci porta con lo scorrimento.
  final _bookingKey = GlobalKey();

  void _scrollToBooking() {
    final ctx = _bookingKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => _content(context),
    );
  }

  /// Preferiti e carrello richiedono un account turista.
  bool _needsTourist(BuildContext context) {
    if (appState.isTourist) return false;
    final t = l10n(context);
    snack(
        context,
        appState.currentUser == null
            ? t.detailNeedLoginFavorites
            : t.detailNeedTourist);
    return true;
  }

  Widget _content(BuildContext context) {
    final t = l10n(context);
    final guide = appState.guideById(tour.guideId);
    final fav = appState.isFavorite(tour.id);
    final inCart = appState.inCart(tour.id);
    final favButton = IconButton(
      tooltip: fav ? t.favRemoveTooltip : t.favAddTooltip,
      icon: Icon(fav ? Icons.favorite : Icons.favorite_border,
          color: fav ? kDanger : null),
      onPressed: () async {
        if (_needsTourist(context)) return;
        try {
          await appState.toggleFavorite(tour.id);
        } catch (e) {
          if (context.mounted) snack(context, '$e');
        }
      },
    );
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 600;
    final photoHeight = (width * 0.6).clamp(240.0, 380.0);
    final accent = categoryColor(tour.category);
    return Scaffold(
      // Sul telefono prezzo e "Prenota" restano sempre a portata di dito.
      bottomNavigationBar:
          narrow ? _BookBar(tour: tour, onBook: _scrollToBooking) : null,
      body: PageBody(
        maxWidth: 860,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ritorno alla pagina di prima: l'elenco resta sotto, quindi
            // ricerca, filtri e scorrimento sono quelli lasciati.
            if (Navigator.of(context).canPop()) ...[
              TextButton.icon(
                key: const ValueKey('tour-back'),
                onPressed: () => Navigator.of(context).maybePop(),
                style: TextButton.styleFrom(
                  foregroundColor: kInk,
                  padding: const EdgeInsets.symmetric(
                      horizontal: kGapSm, vertical: kGapSm),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                icon: const Icon(Icons.arrow_back, size: 18),
                label:
                    Text(widget.fromList ? t.detailBackToTours : t.detailBack),
              ),
              const SizedBox(height: kGapSm),
            ],
            // Foto grande con titolo sopra e sfumatura scura per leggerlo.
            ClipRRect(
              borderRadius: BorderRadius.circular(kRadius),
              child: SizedBox(
                height: photoHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'tour-color-${tour.id}',
                      child: Image.asset(tourImage(tour),
                          fit: BoxFit.cover,
                          color: photoShade(tourImage(tour)),
                          colorBlendMode: BlendMode.srcATop),
                    ),
                    const IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.3, 1],
                            colors: [Color(0x00000000), Color(0xB3000000)],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: kGapSm,
                      right: kGapSm,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: const CircleBorder(),
                        child: favButton,
                      ),
                    ),
                    Positioned(
                      left: narrow ? kGapLg : kGapXl,
                      right: narrow ? kGapLg : kGapXl,
                      bottom: narrow ? kGapLg : 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
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
                                    size: 14, color: accent),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                      '${categoryLabel(context, tour.category)} · ${cityLabel(context, tour.city)}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: accent)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(tour.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontFamily: kSerif,
                                  fontSize: narrow ? 26 : 34,
                                  height: 1.1,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(
                                        color: Color(0x66000000),
                                        blurRadius: 12)
                                  ])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                _Fact(Icons.event,
                    fmtFriendlyDate(context, _date ?? tour.nextStart)),
                _Fact(Icons.schedule, tour.duration),
                _Fact(Icons.language, languageLabel(context, tour.language)),
                _Fact(Icons.euro, fmtPrice(tour.price)),
                _Fact(
                    Icons.event_seat_outlined, t.detailSeatsCount(tour.seats)),
              ],
            ),
            if (tour.upcoming.length > 1) ...[
              const SizedBox(height: 18),
              Text(t.detailChooseDate,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                key: const ValueKey('tour-date-choice'),
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in tour.upcoming)
                    ChoiceChip(
                      label: Text(fmtFriendlyDate(context, d)),
                      selected: _date == d,
                      onSelected: (_) => setState(() => _date = d),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            _Fact(
                Icons.place_outlined, t.detailMeetingPoint(tour.meetingPoint)),
            const SizedBox(height: 20),
            TourMeetingPointMap(
                meetingPoint: tour.meetingPoint, city: tour.city),
            const SizedBox(height: 20),
            Text(tour.description,
                style: const TextStyle(fontSize: 16, height: 1.5)),
            if (tour.isPackage) ...[
              const SizedBox(height: 16),
              InfoBanner(t.detailPackageInfo(
                  guide?.name ?? '',
                  tour.accessories
                      .map((a) => accessoryLabel(context, a))
                      .join(', '))),
            ],
            if (guide?.onlyAccompagnatore == true) ...[
              const SizedBox(height: 16),
              InfoBanner(t.accompagnatoreNotice),
            ],
            const SizedBox(height: 22),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: guide == null
                    ? const CircleAvatar(
                        backgroundColor: kSand,
                        child: Icon(Icons.person_outline, color: kPrimary),
                      )
                    : UserAvatar(user: guide, radius: 22),
                title: Text(guide?.name ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                    '${guide == null ? '' : rolesLabel(context, guide.roles)}'
                    '\n${guide?.languages.map((l) => languageLabel(context, l)).join(', ')}'),
                isThreeLine: true,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: inCart
                  ? null
                  : () async {
                      if (_needsTourist(context)) return;
                      try {
                        await appState.addToCart(tour.id, start: _date);
                        if (context.mounted) {
                          snack(context, t.cartAdded);
                        }
                      } catch (e) {
                        if (context.mounted) snack(context, '$e');
                      }
                    },
              icon:
                  Icon(inCart ? Icons.check : Icons.add_shopping_cart_outlined),
              label: Text(inCart ? t.inCart : t.addToCart),
            ),
            const SizedBox(height: 20),
            BookingForm(key: _bookingKey, tour: tour, date: _date),
            const SizedBox(height: 28),
            WhatsAppOptInCard(source: 'Scheda tour: ${tour.title}'),
            const PlatformDisclaimer(),
          ],
        ),
      ),
    );
  }
}

/// Barra fissa in basso (telefono): prezzo a sinistra, "Prenota" a destra.
class _BookBar extends StatelessWidget {
  const _BookBar({required this.tour, required this.onBook});
  final Tour tour;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        border: const Border(top: BorderSide(color: kLine)),
        boxShadow: [
          BoxShadow(
              color: kInk.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(kGapLg, 10, kGapLg, 10),
          child: Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 12, color: kMuted),
                    children: [
                      TextSpan(text: '${t.tourFrom} '),
                      TextSpan(
                          text: fmtPrice(tour.price),
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: kInk)),
                      TextSpan(text: '  ${t.tourPerPerson}'),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: kGapMd),
              FilledButton(
                key: const ValueKey('book-bar-button'),
                onPressed: onBook,
                style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 22)),
                child: Text(t.detailBookNow),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: kPrimaryText),
          const SizedBox(width: 6),
          Flexible(
              child: Text(text,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      );
}

/// Richiesta di prenotazione non vincolante (BR-006): la conferma è della guida.
class BookingForm extends StatefulWidget {
  const BookingForm({super.key, required this.tour, this.date});
  final Tour tour;

  /// Data scelta nella scheda; null = la prossima uscita.
  final DateTime? date;

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _key = GlobalKey<FormState>();
  late final _name = TextEditingController(
      text: appState.isTourist ? appState.currentUser!.name : '');
  late final _email = TextEditingController(
      text: appState.isTourist ? appState.currentUser!.email : '');
  final _phone = TextEditingController();
  final _message = TextEditingController();
  int _people = 2;
  bool _privacy = false;
  bool _sent = false;
  bool _sending = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final t = l10n(context);
    if (!_key.currentState!.validate()) return;
    if (!_privacy) {
      snack(context, t.bookingNeedPrivacy);
      return;
    }
    setState(() => _sending = true);
    try {
      await appState.addRequest(BookingRequest(
        tourId: widget.tour.id,
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        people: _people,
        message: _message.text.trim(),
        createdAt: DateTime.now(),
        userId: appState.isTourist ? appState.currentUser!.id : null,
        start: widget.date,
      ));
      if (mounted) setState(() => _sent = true);
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
    if (_sent) {
      return InfoBanner(t.bookingSentInfo);
    }
    return Form(
      key: _key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeading(title: t.bookingSectionTitle),
          const SizedBox(height: 12),
          TextFormField(
            controller: _name,
            decoration: InputDecoration(labelText: t.fieldFullName),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? t.validationRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: t.fieldEmail),
            validator: (v) =>
                (v == null || !v.contains('@')) ? t.validationEmail : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: t.fieldPhoneOptional),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(t.fieldPeople),
              const SizedBox(width: 12),
              IconButton.outlined(
                onPressed: _people > 1 ? () => setState(() => _people--) : null,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$_people',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              IconButton.outlined(
                onPressed: () => setState(() => _people++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _message,
            maxLines: 3,
            decoration: InputDecoration(labelText: t.fieldMessageOptional),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _privacy,
            onChanged: (v) => setState(() => _privacy = v ?? false),
            title: Text(t.bookingPrivacyConsent,
                style: const TextStyle(fontSize: 13)),
          ),
          const LegalLink(kind: LegalKind.privacy),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _sending ? null : _submit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _sending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(t.bookingSubmit),
            ),
          ),
        ],
      ),
    );
  }
}

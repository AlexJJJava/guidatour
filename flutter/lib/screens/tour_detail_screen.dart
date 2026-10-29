import 'package:flutter/material.dart';

import '../l10n/labels.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'tour_map.dart';
import 'whatsapp_optin.dart';

void openTour(BuildContext context, Tour t, {bool fromQr = false}) {
  appState.recordVisit(t);
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => TourDetailScreen(tour: t)),
  );
}

class TourDetailScreen extends StatelessWidget {
  const TourDetailScreen({super.key, required this.tour});
  final Tour tour;

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: fav ? t.favRemoveTooltip : t.favAddTooltip,
            icon: Icon(fav ? Icons.favorite : Icons.favorite_border,
                color: fav ? Colors.red : null),
            onPressed: () async {
              if (_needsTourist(context)) return;
              try {
                await appState.toggleFavorite(tour.id);
              } catch (e) {
                if (context.mounted) snack(context, '$e');
              }
            },
          ),
        ],
      ),
      body: PageBody(
        maxWidth: 860,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'tour-color-${tour.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(kRadius),
                child: Image.asset(categoryImage(tour.category),
                    height: 280, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 22),
            Text(
                '${categoryLabel(context, tour.category)} · ${cityLabel(context, tour.city)}'
                    .toUpperCase(),
                style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: kMuted)),
            const SizedBox(height: 6),
            Text(tour.title,
                style: const TextStyle(
                    fontFamily: kSerif,
                    fontSize: 30,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: kInk)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                _Fact(Icons.event, fmtDate(tour.start)),
                _Fact(Icons.schedule, tour.duration),
                _Fact(Icons.language, languageLabel(context, tour.language)),
                _Fact(Icons.euro, fmtPrice(tour.price)),
                _Fact(
                    Icons.event_seat_outlined, t.detailSeatsCount(tour.seats)),
              ],
            ),
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
            const SizedBox(height: 22),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF6EEDF),
                  child: Icon(Icons.person_outline, color: kPrimary),
                ),
                title: Text(guide?.name ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                    '${guide == null ? '' : roleLabel(context, guide.role)}'
                    '${guide?.verified == true ? ' · ${t.verifiedSuffix}' : ''}'
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
                        await appState.addToCart(tour.id);
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
            BookingForm(tour: tour),
            const SizedBox(height: 28),
            WhatsAppOptInCard(source: 'Scheda tour: ${tour.title}'),
            const PlatformDisclaimer(),
          ],
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
          Icon(icon, size: 18, color: kPrimary),
          const SizedBox(width: 6),
          Flexible(
              child: Text(text,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      );
}

/// Richiesta di prenotazione non vincolante (BR-006): la conferma è della guida.
class BookingForm extends StatefulWidget {
  const BookingForm({super.key, required this.tour});
  final Tour tour;

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
            decoration: InputDecoration(
                labelText: t.fieldFullName, border: const OutlineInputBorder()),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? t.validationRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
                labelText: t.fieldEmail, border: const OutlineInputBorder()),
            validator: (v) =>
                (v == null || !v.contains('@')) ? t.validationEmail : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
                labelText: t.fieldPhoneOptional,
                border: const OutlineInputBorder()),
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
            decoration: InputDecoration(
                labelText: t.fieldMessageOptional,
                border: const OutlineInputBorder()),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _privacy,
            onChanged: (v) => setState(() => _privacy = v ?? false),
            title: Text(t.bookingPrivacyConsent,
                style: const TextStyle(fontSize: 13)),
          ),
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

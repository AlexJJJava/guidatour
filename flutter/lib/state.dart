import 'package:flutter/foundation.dart';

import 'models.dart';

/// Stato applicativo in memoria (nessun backend nell'MVP di prototipo).
class AppState extends ChangeNotifier {
  AppState() {
    _seed();
  }

  final List<Guide> guides = [];
  final List<Tour> tours = [];
  final List<BookingRequest> requests = [];
  final List<WhatsAppConsent> consents = [];
  final List<Assignment> assignments = [];
  final List<String> notifications = [];
  Guide? currentUser;
  int _seq = 100;

  static const whatsappConsentText =
      'Acconsento a ricevere su WhatsApp la lista aggiornata di tour ed '
      'escursioni a Roma da GuidaTour. Posso revocare il consenso in qualsiasi '
      'momento rispondendo STOP.';

  void _seed() {
    guides.addAll([
      Guide(
        id: 'g1',
        name: 'Giulia Romano',
        email: 'giulia@demo.it',
        role: Role.guida,
        verified: true,
        languages: ['Italiano', 'English'],
        bio: 'Guida abilitata, archeologia e Roma imperiale.',
      ),
      Guide(
        id: 'g2',
        name: 'Marco Bellini',
        email: 'marco@demo.it',
        role: Role.guida,
        verified: true,
        languages: ['Italiano', 'Français'],
        bio: 'Guida abilitata, Trastevere, ghetto e cucina romana.',
      ),
      Guide(
        id: 'g3',
        name: 'Roma Tour Srl',
        email: 'operatore@demo.it',
        role: Role.tourOperator,
        verified: true,
        bio: 'Tour operator autorizzato, pacchetti completi.',
      ),
      Guide(
        id: 'g5',
        name: 'Elena Turista',
        email: 'elena@demo.it',
        role: Role.turista,
      ),
      Guide(
        id: 'g4',
        name: 'Sara Conti',
        email: 'sara@demo.it',
        role: Role.accompagnatore,
        verified: true,
        languages: ['Italiano', 'English', 'Español'],
        bio: 'Accompagnatrice turistica per gruppi.',
      ),
    ]);
    final now = DateTime.now();
    DateTime at(int days, int h) =>
        DateTime(now.year, now.month, now.day + days, h);
    tours.addAll([
      Tour(
        id: 'colosseo-foro',
        title: 'Colosseo e Foro Romano',
        category: 'Visita guidata',
        language: 'Italiano',
        duration: '2 ore 30',
        start: at(2, 10),
        price: 35,
        meetingPoint: 'Uscita metro Colosseo, Linea B',
        description: 'Un percorso tra anfiteatro Flavio, Foro e Palatino '
            'con una guida abilitata. Ingressi non inclusi.',
        seats: 4,
        guideId: 'g1',
        visits: 128,
        scans: 41,
      ),
      Tour(
        id: 'roma-bambini',
        title: 'Roma per bambini: gladiatori e leggende',
        category: 'Bambini e famiglie',
        language: 'English',
        duration: '2 ore',
        start: at(3, 15),
        price: 25,
        meetingPoint: 'Piazza Venezia, sotto il Vittoriano',
        description: 'Caccia al tesoro tra le rovine, pensata per famiglie '
            'con bambini dai 5 ai 12 anni.',
        seats: 10,
        guideId: 'g1',
        visits: 64,
        scans: 12,
      ),
      Tour(
        id: 'trastevere-sera',
        title: 'Trastevere by night',
        category: 'Serale',
        language: 'Français',
        duration: '2 ore',
        start: at(1, 20),
        price: 22,
        meetingPoint: 'Piazza Trilussa',
        description: 'Vicoli, storie e aneddoti nel rione più vivo di Roma '
            'dopo il tramonto.',
        seats: 12,
        guideId: 'g2',
        visits: 89,
        scans: 30,
      ),
      Tour(
        id: 'roma-gusto',
        title: 'Roma a tavola: mercati e sapori',
        category: 'Enogastronomico',
        language: 'Italiano',
        duration: '3 ore',
        start: at(4, 11),
        price: 45,
        meetingPoint: 'Mercato di Testaccio, ingresso principale',
        description: 'Passeggiata tra i banchi del mercato con assaggi '
            'pagati direttamente in loco.',
        seats: 8,
        guideId: 'g2',
        visits: 40,
        scans: 9,
      ),
      Tour(
        id: 'vaticano-cena',
        title: 'Vaticano + cena romana (pacchetto)',
        category: 'Visita guidata',
        language: 'English',
        duration: '6 ore',
        start: at(5, 16),
        price: 129,
        meetingPoint: 'Viale Vaticano, ingresso Musei',
        description: 'Musei Vaticani con guida e cena tipica in trattoria, '
            'transfer incluso. Organizzato da tour operator autorizzato.',
        seats: 14,
        guideId: 'g3',
        accessories: ['Cena / ristorante', 'Transfer / auto'],
        visits: 52,
        scans: 7,
      ),
    ]);
    requests.addAll([
      BookingRequest(
        tourId: 'colosseo-foro',
        name: 'Anna Schmidt',
        email: 'anna@example.com',
        phone: '+491701234567',
        people: 3,
        message: 'Possiamo avere un tour in tedesco?',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      BookingRequest(
        tourId: 'colosseo-foro',
        name: 'John Miller',
        email: 'john@example.com',
        phone: '+14155550101',
        people: 2,
        message: '',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ]);
  }

  Guide? guideById(String id) {
    for (final g in guides) {
      if (g.id == id) return g;
    }
    return null;
  }

  Tour? tourById(String id) {
    for (final t in tours) {
      if (t.id == id) return t;
    }
    return null;
  }

  // --- Account ---
  String? login(String email) {
    for (final g in guides) {
      if (g.email.toLowerCase() == email.trim().toLowerCase()) {
        currentUser = g;
        notifyListeners();
        return null;
      }
    }
    return 'Nessun account con questa email. Registrati oppure usa un account demo.';
  }

  void loginAs(Guide g) {
    currentUser = g;
    notifyListeners();
  }

  Guide? findByEmail(String email) {
    for (final g in guides) {
      if (g.email.toLowerCase() == email.trim().toLowerCase()) return g;
    }
    return null;
  }

  Guide register(String name, String email, Role role,
      {String provider = 'email'}) {
    final g = Guide(
        id: 'g${_seq++}',
        name: name,
        email: email,
        role: role,
        provider: provider);
    guides.add(g);
    currentUser = g;
    notifyListeners();
    return g;
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  // --- Tour ---
  Tour addTour({
    required String title,
    required String category,
    required String language,
    required String duration,
    required DateTime start,
    required double price,
    required String meetingPoint,
    required String description,
    required int seats,
    required List<String> accessories,
  }) {
    final slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final tour = Tour(
      id: '$slug-${_seq++}',
      title: title,
      category: category,
      language: language,
      duration: duration,
      start: start,
      price: price,
      meetingPoint: meetingPoint,
      description: description,
      seats: seats,
      guideId: currentUser!.id,
      accessories: accessories,
    );
    tours.add(tour);
    notifyListeners();
    return tour;
  }

  void recordVisit(Tour t) {
    t.visits++;
  }

  void recordScan(Tour t) {
    t.scans++;
    t.visits++;
    notifyListeners();
  }

  // --- Account turista: preferiti, carrello, storico ---
  final Map<String, Set<String>> _favorites = {};
  final Map<String, List<CartItem>> _carts = {};

  bool get isTourist => currentUser?.role == Role.turista;

  bool isFavorite(String tourId) =>
      _favorites[currentUser?.id]?.contains(tourId) ?? false;

  List<Tour> get favoriteTours => [
        for (final id in _favorites[currentUser?.id] ?? <String>{})
          if (tourById(id) != null) tourById(id)!,
      ];

  void toggleFavorite(String tourId) {
    final set = _favorites.putIfAbsent(currentUser!.id, () => {});
    if (!set.remove(tourId)) set.add(tourId);
    notifyListeners();
  }

  List<CartItem> get cart => _carts[currentUser?.id] ?? const [];

  bool inCart(String tourId) => cart.any((c) => c.tourId == tourId);

  void addToCart(String tourId, {int people = 2}) {
    if (inCart(tourId)) return;
    _carts
        .putIfAbsent(currentUser!.id, () => [])
        .add(CartItem(tourId, people: people));
    notifyListeners();
  }

  void removeFromCart(CartItem item) {
    _carts[currentUser!.id]?.remove(item);
    notifyListeners();
  }

  void setCartPeople(CartItem item, int people) {
    item.people = people < 1 ? 1 : people;
    notifyListeners();
  }

  double get cartTotal => cart.fold(0.0, (sum, c) {
        final t = tourById(c.tourId);
        return sum + (t == null ? 0 : t.price * c.people);
      });

  /// Invia una richiesta non vincolante per ogni tour nel carrello (nessun pagamento).
  int checkoutCart() {
    final user = currentUser!;
    final items = [...cart];
    for (final c in items) {
      addRequest(BookingRequest(
        tourId: c.tourId,
        name: user.name,
        email: user.email,
        phone: '',
        people: c.people,
        message: 'Richiesta dal carrello',
        createdAt: DateTime.now(),
        userId: user.id,
      ));
    }
    _carts[user.id]?.clear();
    notifyListeners();
    return items.length;
  }

  List<BookingRequest> get myRequests => requests
      .where((r) => r.userId == currentUser?.id)
      .toList()
      .reversed
      .toList();

  void setRequestStatus(BookingRequest r, String status) {
    r.status = status;
    notifyListeners();
  }

  // --- Richieste e consensi ---
  void addRequest(BookingRequest r) {
    requests.add(r);
    final tour = tourById(r.tourId);
    final guide = tour == null ? null : guideById(tour.guideId);
    if (guide != null) {
      notifications.add(
          'Email a ${guide.email}: nuova richiesta da ${r.name} per "${tour!.title}" (${r.people} persone).');
    }
    notifyListeners();
  }

  void addConsent(String phone, String source) {
    consents.add(WhatsAppConsent(
      phone: phone,
      at: DateTime.now(),
      source: source,
      text: whatsappConsentText,
      sender: 'GuidaTour',
    ));
    notifyListeners();
  }

  void revokeConsent(WhatsAppConsent c) {
    c.revoked = true;
    notifyListeners();
  }

  // --- Overbooking (BR-011B) ---
  int requestedPeople(Tour t) => requests
      .where((r) => r.tourId == t.id)
      .fold(0, (sum, r) => sum + r.people);

  List<String> overbookingAlerts(String guideId) {
    final mine = tours.where((t) => t.guideId == guideId).toList();
    final alerts = <String>[];
    for (final t in mine) {
      final n = requestedPeople(t);
      if (n > t.seats) {
        alerts.add(
            '"${t.title}": $n persone richieste per ${t.seats} posti disponibili.');
      }
    }
    for (var i = 0; i < mine.length; i++) {
      for (var j = i + 1; j < mine.length; j++) {
        final a = mine[i], b = mine[j];
        if (a.start.difference(b.start).abs() < const Duration(hours: 3)) {
          alerts.add(
              '"${a.title}" e "${b.title}" si sovrappongono (${fmtDate(a.start)}).');
        }
      }
    }
    return alerts;
  }

  // --- Cambio / cessione tour (BR-011A) ---
  void proposeAssignment(Tour t, Guide to) {
    assignments.add(Assignment(
      id: 'a${_seq++}',
      tourId: t.id,
      fromGuideId: t.guideId,
      toGuideId: to.id,
    ));
    notifications
        .add('Email a ${to.email}: ti è stato proposto il tour "${t.title}".');
    notifyListeners();
  }

  /// La destinataria può solo accettare o rifiutare, mai riassegnare (BR-011A.1).
  void respond(Assignment a, bool accept) {
    a.status = accept ? AssignmentStatus.accettato : AssignmentStatus.rifiutato;
    final owner = guideById(a.fromGuideId);
    final to = guideById(a.toGuideId);
    final tour = tourById(a.tourId);
    notifications.add(
        'Email/WhatsApp a ${owner?.email}: ${to?.name} ha ${accept ? 'accettato' : 'rifiutato'} "${tour?.title}" (${fmtDate(tour!.start)}).');
    notifyListeners();
  }

  void cancelAssignment(Assignment a) {
    a.status = AssignmentStatus.annullato;
    notifyListeners();
  }
}

final appState = AppState();

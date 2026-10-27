import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_client.dart';
import 'models.dart';

const _cityPrefKey = 'city';

/// Stato applicativo: dati pubblici cache-ati localmente, dati dell'utente
/// caricati dal backend dopo il login (Supabase Auth + API GuidaTour).
class AppState extends ChangeNotifier {
  AppState() {
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session == null) {
        if (currentUser != null) _clearUserData();
      } else if (currentUser == null || currentUser!.id != session.user.id) {
        unawaited(_loadMyProfile());
      }
    });
  }

  late final StreamSubscription<AuthState> _authSub;

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  final List<Guide> guides = [];
  final List<Tour> tours = [];
  List<Tour> favoriteTours = [];
  List<CartItem> cart = [];

  /// Richieste ricevute (se guida/operatore) o inviate (se turista).
  List<BookingRequest> requests = [];
  List<BookingRequest> myRequests = [];
  List<WhatsAppConsent> consents = [];
  List<Assignment> assignments = [];
  List<AppNotification> notifications = [];
  Guide? currentUser;
  bool ready = false;

  /// Città selezionata in home: filtra i tour mostrati in tutta l'app.
  String city = 'Roma';

  static const whatsappConsentText =
      'Acconsento a ricevere su WhatsApp la lista aggiornata di tour ed '
      'escursioni a Roma da GuidaTour. Posso revocare il consenso in qualsiasi '
      'momento rispondendo STOP.';

  /// Da chiamare una volta all'avvio dell'app.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    city = prefs.getString(_cityPrefKey) ?? 'Roma';
    await Future.wait([_loadTours(), _loadGuides()]);
    ready = true;
    notifyListeners();
  }

  Future<void> setCity(String newCity) async {
    if (newCity == city) return;
    city = newCity;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityPrefKey, newCity);
    await _loadTours();
  }

  Future<void> _loadTours() async {
    try {
      final json = await api.get('/tours', query: {'city': city}) as Map;
      final list = (json['tours'] as List)
          .map((j) => Tour.fromJson(j as Map<String, dynamic>))
          .toList();
      tours
        ..clear()
        ..addAll(list);
    } catch (_) {
      // Resta con la cache precedente (vuota al primo avvio).
    }
    notifyListeners();
  }

  /// Aggiunge/aggiorna un tour nella cache locale senza perdere gli altri
  /// (usato quando un tour arriva da un endpoint diverso da GET /tours,
  /// es. carrello o dashboard, e potrebbe non essere tra i futuri).
  void _cacheTour(Tour t) {
    final i = tours.indexWhere((x) => x.id == t.id);
    if (i >= 0) {
      tours[i] = t;
    } else {
      tours.add(t);
    }
    if (t.guideId == currentUser?.id) {
      final mi = myTours.indexWhere((x) => x.id == t.id);
      if (mi >= 0) {
        myTours[mi] = t;
      } else {
        myTours.add(t);
      }
    }
  }

  Future<void> _loadGuides() async {
    try {
      final json = await api.get('/guides') as Map;
      final list = (json['guides'] as List)
          .map((j) => Guide.fromPublicJson(j as Map<String, dynamic>))
          .toList();
      guides
        ..clear()
        ..addAll(list);
    } catch (_) {
      // Resta con la cache precedente.
    }
    notifyListeners();
  }

  Future<void> _loadMyProfile() async {
    try {
      final json = await api.get('/me') as Map<String, dynamic>;
      currentUser = Guide.fromProfileJson(json);
    } catch (_) {
      currentUser = null;
      notifyListeners();
      return;
    }
    if (currentUser!.role.isProfessional) {
      await _loadProfessionalData();
    } else {
      await _loadTouristData();
    }
    notifyListeners();
  }

  Future<void> _loadTouristData() async {
    try {
      final favJson = await api.get('/me/favorites') as Map;
      favoriteTours = (favJson['tours'] as List)
          .map((j) => Tour.fromJson(j as Map<String, dynamic>))
          .toList();
      for (final t in favoriteTours) {
        _cacheTour(t);
      }
    } catch (_) {
      favoriteTours = [];
    }
    try {
      final cartJson = await api.get('/me/cart') as Map;
      final items = (cartJson['items'] as List).cast<Map<String, dynamic>>();
      cart = items
          .map((i) => CartItem(i['tourId'] as String,
              people: (i['people'] as num).toInt()))
          .toList();
      for (final i in items) {
        _cacheTour(Tour.fromJson(i['tour'] as Map<String, dynamic>));
      }
    } catch (_) {
      cart = [];
    }
    try {
      final reqJson = await api.get('/me/requests') as Map;
      myRequests = (reqJson['requests'] as List)
          .map((j) => BookingRequest.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      myRequests = [];
    }
    notifyListeners();
  }

  /// Tutti i tour del professionista, in qualunque città (indipendente dal
  /// filtro città della home, a differenza di [tours]).
  List<Tour> myTours = [];

  Future<void> _loadProfessionalData() async {
    try {
      final toursJson = await api
          .get('/tours', query: {'guideId': currentUser!.id, 'includePast': 'true'}) as Map;
      myTours = (toursJson['tours'] as List)
          .map((j) => Tour.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      myTours = [];
    }
    try {
      final reqJson = await api.get('/requests/received') as Map;
      requests = (reqJson['requests'] as List)
          .map((j) => BookingRequest.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      requests = [];
    }
    try {
      final notifJson = await api.get('/me/notifications') as Map;
      notifications = (notifJson['notifications'] as List)
          .map((j) => AppNotification.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      notifications = [];
    }
    try {
      final asJson = await api.get('/assignments') as Map;
      assignments = (asJson['assignments'] as List)
          .map((j) => Assignment.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      assignments = [];
    }
    try {
      // Riservato agli admin: per gli altri il backend risponde 403, lo
      // ignoriamo e la lista resta vuota.
      final consJson = await api.get('/consents') as Map;
      consents = (consJson['consents'] as List)
          .map((j) => WhatsAppConsent.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      consents = [];
    }
    notifyListeners();
  }

  void _clearUserData() {
    currentUser = null;
    favoriteTours = [];
    cart = [];
    myTours = [];
    requests = [];
    myRequests = [];
    consents = [];
    assignments = [];
    notifications = [];
    notifyListeners();
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

  /// Restituisce un messaggio di errore, o null se l'accesso è riuscito.
  Future<String?> loginWithPassword(String email, String password) async {
    try {
      await Supabase.instance.client.auth
          .signInWithPassword(email: email.trim(), password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Accesso non riuscito. Controlla la connessione e riprova.';
    }
  }

  /// Restituisce un messaggio da mostrare (errore, o avviso di conferma email),
  /// oppure null se la registrazione ha avviato subito una sessione valida.
  Future<String?> registerWithPassword(
      String name, String email, String password, Role role) async {
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name.trim(), 'role': role.name},
      );
      if (res.session == null) {
        return 'Account creato: controlla la tua email per confermarlo prima di accedere.';
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Registrazione non riuscita. Controlla la connessione e riprova.';
    }
  }

  Future<void> logout() => Supabase.instance.client.auth.signOut();

  // --- Tour ---
  Future<Tour> addTour({
    required String title,
    required String city,
    required String category,
    required String language,
    required String duration,
    required DateTime start,
    required double price,
    required String meetingPoint,
    required String description,
    required int seats,
    required List<String> accessories,
  }) async {
    final json = await api.post('/tours', {
      'title': title,
      'city': city,
      'category': category,
      'language': language,
      'duration': duration,
      'start': start.toUtc().toIso8601String(),
      'price': price,
      'meetingPoint': meetingPoint,
      'description': description,
      'seats': seats,
      'accessories': accessories,
    }) as Map<String, dynamic>;
    final tour = Tour.fromJson(json);
    _cacheTour(tour);
    notifyListeners();
    return tour;
  }

  Future<Tour> updateTour(
    String id, {
    required String title,
    required String city,
    required String category,
    required String language,
    required String duration,
    required DateTime start,
    required double price,
    required String meetingPoint,
    required String description,
    required int seats,
    required List<String> accessories,
  }) async {
    final json = await api.patch('/tours/$id', {
      'title': title,
      'city': city,
      'category': category,
      'language': language,
      'duration': duration,
      'start': start.toUtc().toIso8601String(),
      'price': price,
      'meetingPoint': meetingPoint,
      'description': description,
      'seats': seats,
      'accessories': accessories,
    }) as Map<String, dynamic>;
    final tour = Tour.fromJson(json);
    _cacheTour(tour);
    notifyListeners();
    return tour;
  }

  Future<void> deleteTour(String id) async {
    await api.delete('/tours/$id');
    tours.removeWhere((t) => t.id == id);
    myTours.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String bio,
    required List<String> languages,
  }) async {
    final json = await api.patch('/me', {
      'name': name,
      'bio': bio,
      'languages': languages,
    }) as Map<String, dynamic>;
    currentUser = Guide.fromProfileJson(json);
    notifyListeners();
  }

  Future<void> markNotificationRead(AppNotification n) async {
    if (n.isRead) return;
    await api.post('/me/notifications/${n.id}/read');
    n.readAt = DateTime.now();
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    await api.post('/me/notifications/read');
    final now = DateTime.now();
    for (final n in notifications) {
      n.readAt ??= now;
    }
    notifyListeners();
  }

  Future<void> recordVisit(Tour t) async {
    try {
      await api.post('/tours/${t.id}/visit');
    } catch (_) {
      // Non blocca l'esperienza utente.
    }
  }

  Future<void> recordScan(Tour t) async {
    await api.post('/tours/${t.id}/scan');
    t.scans++;
    t.visits++;
    notifyListeners();
  }

  // --- Account turista: preferiti, carrello, storico ---

  bool get isTourist => currentUser != null && !currentUser!.role.isProfessional;

  bool isFavorite(String tourId) =>
      favoriteTours.any((t) => t.id == tourId);

  Future<void> toggleFavorite(String tourId) async {
    if (isFavorite(tourId)) {
      await api.delete('/me/favorites/$tourId');
      favoriteTours.removeWhere((t) => t.id == tourId);
    } else {
      await api.put('/me/favorites/$tourId');
      final t = tourById(tourId);
      if (t != null) favoriteTours.add(t);
    }
    notifyListeners();
  }

  bool inCart(String tourId) => cart.any((c) => c.tourId == tourId);

  Future<void> addToCart(String tourId, {int people = 2}) async {
    if (inCart(tourId)) return;
    await api.post('/me/cart', {'tourId': tourId, 'people': people});
    cart.add(CartItem(tourId, people: people));
    notifyListeners();
  }

  Future<void> removeFromCart(CartItem item) async {
    await api.delete('/me/cart/${item.tourId}');
    cart.remove(item);
    notifyListeners();
  }

  Future<void> setCartPeople(CartItem item, int people) async {
    final n = people < 1 ? 1 : people;
    await api.patch('/me/cart/${item.tourId}', {'people': n});
    item.people = n;
    notifyListeners();
  }

  double get cartTotal => cart.fold(0.0, (sum, c) {
        final t = tourById(c.tourId);
        return sum + (t == null ? 0 : t.price * c.people);
      });

  /// Invia una richiesta non vincolante per ogni tour nel carrello (nessun pagamento).
  Future<int> checkoutCart() async {
    final json = await api.post('/me/cart/checkout', {
      'phone': '',
      'message': 'Richiesta dal carrello',
    }) as Map;
    final n = (json['requestIds'] as List).length;
    cart = [];
    unawaited(_loadTouristData());
    notifyListeners();
    return n;
  }

  Future<void> setRequestStatus(BookingRequest r, String status) async {
    await api.patch('/requests/${r.id}', {'status': status});
    r.status = status;
    notifyListeners();
  }

  // --- Richieste e consensi ---
  Future<void> addRequest(BookingRequest r) async {
    await api.post('/tours/${r.tourId}/requests', {
      'name': r.name,
      'email': r.email,
      'phone': r.phone,
      'people': r.people,
      'message': r.message,
    });
  }

  Future<void> addConsent(String phone, String source) async {
    await api.post('/consents', {'phone': phone, 'source': source});
  }

  Future<void> revokeConsent(WhatsAppConsent c) async {
    await api.post('/consents/${c.id}/revoke');
    c.revoked = true;
    notifyListeners();
  }

  // --- Overbooking (BR-011B) ---
  int requestedPeople(Tour t) => requests
      .where((r) => r.tourId == t.id)
      .fold(0, (sum, r) => sum + r.people);

  List<String> overbookingAlerts(String guideId) {
    final mine = myTours.where((t) => t.guideId == guideId).toList();
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
  Future<void> proposeAssignment(Tour t, Guide to) async {
    final json = await api
        .post('/assignments', {'tourId': t.id, 'toGuideId': to.id}) as Map<String, dynamic>;
    assignments.insert(0, Assignment.fromJson(json));
    notifyListeners();
  }

  /// La destinataria può solo accettare o rifiutare, mai riassegnare (BR-011A.1).
  Future<void> respond(Assignment a, bool accept) async {
    final json = await api
        .post('/assignments/${a.id}/respond', {'accept': accept}) as Map<String, dynamic>;
    _replaceAssignment(Assignment.fromJson(json));
  }

  Future<void> cancelAssignment(Assignment a) async {
    final json =
        await api.post('/assignments/${a.id}/cancel') as Map<String, dynamic>;
    _replaceAssignment(Assignment.fromJson(json));
  }

  void _replaceAssignment(Assignment updated) {
    final i = assignments.indexWhere((x) => x.id == updated.id);
    if (i >= 0) {
      assignments[i] = updated;
    } else {
      assignments.add(updated);
    }
    notifyListeners();
  }
}

final appState = AppState();

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_client.dart';
import 'models.dart';

const _cityPrefKey = 'city';
const _seenAnswersKey = 'seenAnswers';

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

  /// Registrazioni professionali in attesa (solo per gli admin).
  int pendingRegistrations = 0;

  /// Città scelta dalla barra in alto: filtra i tour mostrati in tutta
  /// l'app. null = tutta Italia (così al primo accesso).
  String? city;

  static const whatsappConsentText =
      'Acconsento a ricevere su WhatsApp la lista aggiornata di tour ed '
      'escursioni a Roma da GuidaTour. Posso revocare il consenso in qualsiasi '
      'momento rispondendo STOP.';

  /// Da chiamare una volta all'avvio dell'app.
  /// Risposte (richiesta:stato) già viste nel carrello.
  Set<String> _seenAnswers = {};

  static String _answerKey(BookingRequest r) => '${r.id}:${r.status}';

  /// Richieste confermate o rifiutate che il turista non ha ancora visto.
  bool isNewAnswer(BookingRequest r) =>
      r.status != 'inviata' && !_seenAnswers.contains(_answerKey(r));

  int get unseenAnswers => myRequests.where(isNewAnswer).length;

  Future<void> markAnswersSeen() async {
    if (unseenAnswers == 0) return;
    _seenAnswers = {..._seenAnswers, ...myRequests.map(_answerKey)};
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_seenAnswersKey, _seenAnswers.toList());
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    city = prefs.getString(_cityPrefKey);
    _seenAnswers = {...?prefs.getStringList(_seenAnswersKey)};
    await Future.wait([_loadTours(), _loadGuides()]);
    ready = true;
    notifyListeners();
  }

  Future<void> setCity(String? newCity) async {
    if (newCity == city) return;
    city = newCity;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (newCity == null) {
      await prefs.remove(_cityPrefKey);
    } else {
      await prefs.setString(_cityPrefKey, newCity);
    }
    await _loadTours();
  }

  Future<void> _loadTours() async {
    try {
      final json = await api
          .get('/tours', query: {if (city != null) 'city': city!}) as Map;
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
    if (currentUser!.isAdmin) unawaited(refreshPendingRegistrations());
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
      final toursJson = await api.get('/tours',
          query: {'guideId': currentUser!.id, 'includePast': 'true'}) as Map;
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
    pendingRegistrations = 0;
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
      String name, String email, String password, List<Role> roles) async {
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'name': name.trim(),
          'role': primaryRole(roles).name,
          'roles': [for (final r in roles) r.name],
        },
      );
      if (res.session == null) {
        return roles.isNotEmpty
            ? 'Account creato: controlla la tua email per confermarlo. Prima di poter accedere, un amministratore dovrà approvare la registrazione.'
            : 'Account creato: controlla la tua email per confermarlo prima di accedere.';
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Registrazione non riuscita. Controlla la connessione e riprova.';
    }
  }

  Future<void> logout() => Supabase.instance.client.auth.signOut();

  /// Cancella l'account e tutti i dati collegati (funzione delete_my_account,
  /// migrazione 0010), poi chiude la sessione. La foto si toglie prima con
  /// Storage: il database non può cancellare i file.
  Future<void> deleteAccount() async {
    final client = Supabase.instance.client;
    if (currentUser?.avatarUrl != null) {
      try {
        await client.storage
            .from('avatars')
            .remove(['${currentUser!.id}/avatar.png']);
      } catch (_) {
        // Una foto non cancellata non deve bloccare la cancellazione.
      }
    }
    await client.rpc('delete_my_account');
    await client.auth.signOut();
  }

  // --- Admin: approvazione registrazioni ---

  /// Registrazioni professionali nello stato indicato.
  Future<List<Guide>> loadRegistrations(String status) async {
    final json =
        await api.get('/admin/registrations', query: {'status': status}) as Map;
    return (json['registrations'] as List)
        .map((j) => Guide.fromProfileJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> refreshPendingRegistrations() async {
    try {
      pendingRegistrations = (await loadRegistrations('in_attesa')).length;
    } catch (_) {
      pendingRegistrations = 0;
    }
    notifyListeners();
  }

  /// [status]: 'approvato' o 'rifiutato'.
  Future<void> decideRegistration(String userId, String status) async {
    await api.post('/admin/registrations/$userId', {'status': status});
    await Future.wait([refreshPendingRegistrations(), _loadGuides()]);
  }

  // --- Admin: gestione ---

  Future<Map<String, dynamic>> loadAdminOverview() async =>
      await api.get('/admin/overview') as Map<String, dynamic>;

  /// Professionisti approvati o sospesi, con il numero dei loro tour.
  Future<List<(Guide, int)>> loadAdminProfessionals() async {
    final json = await api.get('/admin/professionals') as Map;
    return [
      for (final p
          in (json['professionals'] as List).cast<Map<String, dynamic>>())
        (Guide.fromProfileJson(p), (p['tours'] as num? ?? 0).toInt()),
    ];
  }

  Future<void> setSuspended(String userId, bool suspended) async {
    await api.post('/admin/professionals/$userId', {'suspended': suspended});
    await Future.wait([_loadGuides(), _loadTours()]);
  }

  Future<List<AdminTour>> loadAdminTours() async {
    final json = await api.get('/admin/tours') as Map;
    return [
      for (final j in (json['tours'] as List).cast<Map<String, dynamic>>())
        AdminTour.fromJson(j),
    ];
  }

  Future<void> adminDeleteTour(String id) async {
    await api.delete('/admin/tours/$id');
    tours.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> loadConsents() async {
    final json = await api.get('/consents') as Map;
    consents = (json['consents'] as List)
        .map((j) => WhatsAppConsent.fromJson(j as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  // --- Tour ---
  Future<Tour> addTour({
    required String title,
    required String city,
    required String category,
    required String language,
    required String duration,
    required List<DateTime> dates,
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
      'start': dates.first.toUtc().toIso8601String(),
      'dates': [for (final d in dates) d.toUtc().toIso8601String()],
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
    required List<DateTime> dates,
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
      'start': dates.first.toUtc().toIso8601String(),
      'dates': [for (final d in dates) d.toUtc().toIso8601String()],
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
    String? city,
  }) async {
    final json = await api.patch('/me', {
      'name': name,
      'bio': bio,
      'languages': languages,
      if (city != null) 'city': city,
    }) as Map<String, dynamic>;
    currentUser = Guide.fromProfileJson(json);
    notifyListeners();
  }

  /// Sostituisce la foto profilo: l'indirizzo cambia a ogni caricamento,
  /// altrimenti il browser continuerebbe a mostrare quella vecchia.
  Future<void> uploadAvatar(Uint8List png) async {
    final bucket = Supabase.instance.client.storage.from('avatars');
    final path = '${currentUser!.id}/avatar.png';
    await bucket.uploadBinary(path, png,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/png'));
    final url = bucket.getPublicUrl(path);
    await _setAvatar('$url?v=${DateTime.now().millisecondsSinceEpoch}');
  }

  Future<void> removeAvatar() async {
    await Supabase.instance.client.storage
        .from('avatars')
        .remove(['${currentUser!.id}/avatar.png']);
    await _setAvatar(null);
  }

  Future<void> _setAvatar(String? url) async {
    final json = await api.patch('/me', {'avatarUrl': url});
    currentUser = Guide.fromProfileJson(json as Map<String, dynamic>);
    notifyListeners();
  }

  /// Togliere un ruolo vale subito; aggiungerlo passa dall'approvazione.
  Future<void> requestRoles(List<Role> roles) async {
    await api.put('/me/roles', {
      'roles': [for (final r in roles) r.name],
    });
    // Il profilo può diventare turista o professionista: si ricarica tutto.
    await _loadMyProfile();
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

  /// Tour aperto da un link: può non essere tra i futuri già caricati.
  Future<Tour?> fetchTour(String id) async {
    try {
      final tour =
          Tour.fromJson(await api.get('/tours/$id') as Map<String, dynamic>);
      _cacheTour(tour);
      notifyListeners();
      return tour;
    } catch (_) {
      return null;
    }
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

  bool get isTourist =>
      currentUser != null && !currentUser!.role.isProfessional;

  bool isFavorite(String tourId) => favoriteTours.any((t) => t.id == tourId);

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

  Future<void> addToCart(String tourId,
      {int people = 2, DateTime? start}) async {
    if (inCart(tourId)) return;
    await api.post('/me/cart', {
      'tourId': tourId,
      'people': people,
      if (start != null) 'start': start.toUtc().toIso8601String(),
    });
    cart.add(CartItem(tourId, people: people, start: start));
    notifyListeners();
  }

  /// Cambia la data scelta per un tour già nel carrello.
  Future<void> setCartDate(CartItem item, DateTime start) async {
    await api.patch(
        '/me/cart/${item.tourId}', {'start': start.toUtc().toIso8601String()});
    item.start = start;
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
      if (r.start != null) 'start': r.start!.toUtc().toIso8601String(),
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

  /// I posti valgono per ogni uscita: persone richieste data per data (le
  /// richieste senza data contano sulla prossima uscita).
  Map<DateTime, int> requestedPeopleByDate(Tour t) {
    final out = <DateTime, int>{};
    for (final r in requests.where((r) => r.tourId == t.id)) {
      final d = r.start ?? t.nextStart;
      out[d] = (out[d] ?? 0) + r.people;
    }
    return out;
  }

  List<String> overbookingAlerts(String guideId) {
    final mine = myTours.where((t) => t.guideId == guideId).toList();
    final alerts = <String>[];
    final now = DateTime.now();
    for (final t in mine) {
      requestedPeopleByDate(t).forEach((d, n) {
        if (n > t.seats && !d.isBefore(now)) {
          final when = t.dates.length > 1 ? ' (${fmtDate(d)})' : '';
          alerts.add('"${t.title}"$when: $n persone richieste per '
              '${t.seats} posti disponibili.');
        }
      });
    }
    // Ogni uscita futura di ogni tour, in ordine di data.
    final slots = [
      for (final t in mine)
        for (final d in t.upcoming) (tour: t, at: d),
    ]..sort((a, b) => a.at.compareTo(b.at));
    for (var i = 0; i < slots.length; i++) {
      for (var j = i + 1; j < slots.length; j++) {
        final a = slots[i], b = slots[j];
        if (b.at.difference(a.at) >= const Duration(hours: 3)) break;
        if (a.tour.id == b.tour.id) continue;
        alerts.add('"${a.tour.title}" e "${b.tour.title}" si sovrappongono '
            '(${fmtDate(a.at)}).');
      }
    }
    return alerts;
  }

  // --- Cambio / cessione tour (BR-011A) ---
  Future<void> proposeAssignment(Tour t, Guide to) async {
    final json =
        await api.post('/assignments', {'tourId': t.id, 'toGuideId': to.id})
            as Map<String, dynamic>;
    assignments.insert(0, Assignment.fromJson(json));
    notifyListeners();
  }

  /// La destinataria può solo accettare o rifiutare, mai riassegnare (BR-011A.1).
  Future<void> respond(Assignment a, bool accept) async {
    final json =
        await api.post('/assignments/${a.id}/respond', {'accept': accept})
            as Map<String, dynamic>;
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

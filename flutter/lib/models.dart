import 'package:flutter/widgets.dart' show StringCharacters;

import 'app_config.dart';

/// Profili professionali distinti (BRD BR-014D, §13.4).
enum Role { turista, guida, accompagnatore, tourOperator }

extension RoleLabel on Role {
  bool get isProfessional => this != Role.turista;
}

Role roleFromString(String? s) =>
    Role.values.firstWhere((r) => r.name == s, orElse: () => Role.turista);

/// Ruoli professionali, nell'ordine in cui si mostrano.
const professionalRoles = [Role.guida, Role.accompagnatore, Role.tourOperator];

/// Ruolo principale fra quelli scelti (come nel database): guida, poi tour
/// operator, poi accompagnatore.
Role primaryRole(Iterable<Role> roles) => roles.contains(Role.guida)
    ? Role.guida
    : roles.contains(Role.tourOperator)
        ? Role.tourOperator
        : roles.contains(Role.accompagnatore)
            ? Role.accompagnatore
            : Role.turista;

/// Ruoli professionali dal JSON; prima della migrazione 0006 c'è solo `role`.
List<Role> _rolesFrom(Map<String, dynamic> j, Role role) {
  final list = (j['roles'] as List?)
      ?.map((r) => roleFromString(r as String?))
      .where((r) => r.isProfessional)
      .toSet();
  if (list != null && list.isNotEmpty) {
    return [
      for (final r in professionalRoles)
        if (list.contains(r)) r
    ];
  }
  return role.isProfessional ? [role] : const [];
}

class Guide {
  Guide({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.verified = false,
    this.languages = const ['Italiano'],
    this.bio = '',
    this.provider = 'email',
    this.isAdmin = false,
    this.city = 'Roma',
    this.approvalStatus = 'approvato',
    this.createdAt,
    this.avatarUrl,
    List<Role>? roles,
    this.requestedRoles = const [],
    this.pendingRoles = const [],
  }) : roles = roles ?? (role.isProfessional ? [role] : const []);
  final String id;
  final String name;
  final String email;

  /// Ruolo principale; per i controlli usare [roles] e [has].
  final Role role;

  /// Ruoli professionali (vuoto per un turista).
  final List<Role> roles;
  final String provider;
  final bool verified;
  final List<String> languages;
  final String bio;
  final bool isAdmin;
  final String city;

  /// 'in_attesa' | 'approvato' | 'rifiutato': guide, accompagnatori e tour
  /// operator restano in attesa finché un admin non li approva.
  final String approvalStatus;
  final DateTime? createdAt;
  final String? avatarUrl;

  /// Ruoli professionali chiesti alla registrazione e non ancora approvati
  /// (o rifiutati): finché non c'è l'approvazione l'utente è un turista.
  final List<Role> requestedRoles;

  /// Ruoli aggiunti dal profilo da un professionista già approvato: si
  /// attivano quando l'admin li approva (gli altri restano validi).
  final List<Role> pendingRoles;

  /// Ruoli scelti dall'utente: attivi, in attesa o chiesti in registrazione.
  List<Role> get chosenRoles => [
        for (final r in professionalRoles)
          if (roles.contains(r) ||
              pendingRoles.contains(r) ||
              requestedRoles.contains(r))
            r
      ];

  bool has(Role r) => roles.contains(r);

  /// Solo accompagnatore: niente visite guidate né testi su beni culturali.
  bool get onlyAccompagnatore =>
      has(Role.accompagnatore) && !has(Role.guida) && !has(Role.tourOperator);

  /// Prima lettera di nome e cognome, per il pallino senza foto.
  String get initials {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    final first = words.first.characters.first;
    final last = words.length > 1 ? words.last.characters.first : '';
    return '$first$last'.toUpperCase();
  }

  bool get isApproved => approvalStatus == 'approvato';

  /// Dal profilo pubblico (`GET /guides`, `/tours/:id`): niente email.
  factory Guide.fromPublicJson(Map<String, dynamic> j) => Guide(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        email: '',
        role: roleFromString(j['role'] as String?),
        roles: _rolesFrom(j, roleFromString(j['role'] as String?)),
        verified: j['verified'] as bool? ?? false,
        languages:
            (j['languages'] as List?)?.cast<String>() ?? const ['Italiano'],
        bio: j['bio'] as String? ?? '',
        city: j['city'] as String? ?? 'Roma',
      );

  /// Dal proprio profilo (`GET /me`): dati completi. Un professionista non
  /// ancora approvato usa l'app come turista.
  factory Guide.fromProfileJson(Map<String, dynamic> j) {
    final role = roleFromString(j['role'] as String?);
    final roles = _rolesFrom(j, role);
    final approval = j['approvalStatus'] as String? ?? 'approvato';
    final waiting = roles.isNotEmpty && approval != 'approvato';
    return Guide._fromProfileJson(j,
        role: waiting ? Role.turista : role,
        roles: waiting ? const [] : roles,
        requestedRoles: waiting ? roles : const []);
  }

  factory Guide._fromProfileJson(Map<String, dynamic> j,
          {required Role role,
          required List<Role> roles,
          required List<Role> requestedRoles}) =>
      Guide(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        role: role,
        roles: roles,
        requestedRoles: requestedRoles,
        pendingRoles: [
          for (final r in (j['pendingRoles'] as List? ?? const []))
            roleFromString(r as String?)
        ].where((r) => r.isProfessional).toList(),
        verified: j['verified'] as bool? ?? false,
        languages:
            (j['languages'] as List?)?.cast<String>() ?? const ['Italiano'],
        bio: j['bio'] as String? ?? '',
        provider: j['provider'] as String? ?? 'email',
        isAdmin: j['isAdmin'] as bool? ?? false,
        city: j['city'] as String? ?? 'Roma',
        approvalStatus: j['approvalStatus'] as String? ?? 'approvato',
        avatarUrl: j['avatarUrl'] as String?,
        createdAt: j['createdAt'] == null
            ? null
            : DateTime.parse(j['createdAt'] as String).toLocal(),
      );
}

/// Tour visto dall'admin: con il nome e lo stato di chi lo organizza.
class AdminTour {
  AdminTour(this.tour, this.guideName, this.guideStatus);
  final Tour tour;
  final String guideName;
  final String guideStatus;

  factory AdminTour.fromJson(Map<String, dynamic> j) => AdminTour(
      Tour.fromJson(j),
      j['guideName'] as String? ?? '',
      j['guideStatus'] as String? ?? 'approvato');
}

/// Servizi accessori che possono trasformare un tour in pacchetto turistico (BR-014G).
const accessoryServices = [
  'Cena / ristorante',
  'Transfer / auto',
  'Biglietti / ingressi',
  'Hotel',
  'Esperienza food',
];

const tourCategories = [
  'Visita guidata',
  'Tour a piedi',
  'Enogastronomico',
  'Bambini e famiglie',
  'Serale',
  'Accompagnamento',
];

const tourLanguages = ['Italiano', 'English', 'Español', 'Français', 'Deutsch'];

const tourCities = [
  'Roma',
  'Milano',
  'Firenze',
  'Venezia',
  'Napoli',
  'Bologna',
  'Torino',
];

/// Date massime per tour (lo stesso limite del database).
const maxTourDates = 60;

/// Le date dopo [from], una a settimana alla stessa ora, fino al giorno [until].
List<DateTime> weeklyDates(DateTime from, DateTime until) {
  final end = DateTime(until.year, until.month, until.day, 23, 59);
  final out = <DateTime>[];
  for (var i = 1;; i++) {
    final d = DateTime(
        from.year, from.month, from.day + 7 * i, from.hour, from.minute);
    if (d.isAfter(end)) return out;
    out.add(d);
  }
}

/// Vero se le date sono tutte a una settimana di distanza (stesso giorno e ora).
bool isWeekly(List<DateTime> dates) {
  if (dates.length < 2) return false;
  for (var i = 1; i < dates.length; i++) {
    final p = dates[i - 1];
    if (dates[i] != DateTime(p.year, p.month, p.day + 7, p.hour, p.minute)) {
      return false;
    }
  }
  return true;
}

class Tour {
  Tour({
    required this.id,
    required this.title,
    required this.city,
    required this.category,
    required this.language,
    required this.duration,
    required this.start,
    required this.price,
    required this.meetingPoint,
    required this.description,
    required this.seats,
    required this.guideId,
    List<DateTime>? dates,
    this.accessories = const [],
    this.visits = 0,
    this.scans = 0,
  }) : dates = (dates == null || dates.isEmpty) ? [start] : dates;
  final String id;
  final String title;
  final String city;
  final String category;
  final String language;
  final String duration;

  /// Prossima uscita (o l'ultima, se sono tutte passate).
  final DateTime start;

  /// Tutte le date del tour, in ordine: lo stesso tour esce più volte.
  final List<DateTime> dates;
  final double price;
  final String meetingPoint;
  final String description;
  final int seats;
  final String guideId;
  final List<String> accessories;
  int visits;
  int scans;

  bool get isPackage => accessories.isNotEmpty;
  String get url => '$publicSiteUrl?tour=$id';

  /// Date ancora da svolgere.
  List<DateTime> get upcoming {
    final now = DateTime.now();
    return dates.where((d) => !d.isBefore(now)).toList();
  }

  /// Passato quando anche l'ultima data è alle spalle.
  bool get isPast => dates.last.isBefore(DateTime.now());

  /// Prossima data da mostrare negli elenchi.
  DateTime get nextStart {
    final u = upcoming;
    return u.isEmpty ? dates.last : u.first;
  }

  factory Tour.fromJson(Map<String, dynamic> j) => Tour(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        city: j['city'] as String? ?? 'Roma',
        category: j['category'] as String? ?? '',
        language: j['language'] as String? ?? '',
        duration: j['duration'] as String? ?? '',
        start: DateTime.parse(j['start'] as String).toLocal(),
        dates: (j['dates'] as List?)
            ?.map((d) => DateTime.parse(d as String).toLocal())
            .toList(),
        price: (j['price'] as num).toDouble(),
        meetingPoint: j['meetingPoint'] as String? ?? '',
        description: j['description'] as String? ?? '',
        seats: (j['seats'] as num).toInt(),
        guideId: j['guideId'] as String,
        accessories: (j['accessories'] as List?)?.cast<String>() ?? const [],
        visits: (j['visits'] as num?)?.toInt() ?? 0,
        scans: (j['scans'] as num?)?.toInt() ?? 0,
      );
}

class BookingRequest {
  BookingRequest({
    this.id,
    required this.tourId,
    required this.name,
    required this.email,
    required this.phone,
    required this.people,
    required this.message,
    required this.createdAt,
    this.userId,
    this.status = 'inviata',
    this.start,
  });
  final String? id;
  final String tourId;

  /// Data del tour scelta dal turista (le richieste vecchie non ce l'hanno).
  final DateTime? start;
  final String name;
  final String email;
  final String phone;
  final int people;
  final String message;
  final DateTime createdAt;

  /// Account del turista, se era loggato quando ha inviato la richiesta.
  final String? userId;

  /// 'inviata' → 'confermata' o 'rifiutata' dalla guida.
  String status;

  factory BookingRequest.fromJson(Map<String, dynamic> j) => BookingRequest(
        id: j['id'] as String?,
        tourId: j['tourId'] as String,
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        people: (j['people'] as num).toInt(),
        message: j['message'] as String? ?? '',
        createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
        userId: j['userId'] as String?,
        status: j['status'] as String? ?? 'inviata',
        start: j['start'] == null
            ? null
            : DateTime.parse(j['start'] as String).toLocal(),
      );
}

/// Voce del carrello: un tour, la data scelta e il numero di persone.
class CartItem {
  CartItem(this.tourId, {this.people = 2, this.start});
  final String tourId;
  int people;

  /// Data scelta; null = la prossima uscita del tour.
  DateTime? start;

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        j['tourId'] as String,
        people: (j['people'] as num).toInt(),
        start: j['start'] == null
            ? null
            : DateTime.parse(j['start'] as String).toLocal(),
      );
}

/// Prova del consenso WhatsApp (BR-011D).
class WhatsAppConsent {
  WhatsAppConsent({
    this.id,
    required this.phone,
    required this.at,
    required this.source,
    required this.text,
    required this.sender,
    this.revoked = false,
  });
  final String? id;
  final String phone;
  final DateTime at;
  final String source;
  final String text;
  final String sender;
  bool revoked;

  factory WhatsAppConsent.fromJson(Map<String, dynamic> j) => WhatsAppConsent(
        id: j['id'] as String?,
        phone: j['phone'] as String? ?? '',
        at: DateTime.parse(j['at'] as String).toLocal(),
        source: j['source'] as String? ?? '',
        text: j['text'] as String? ?? '',
        sender: j['sender'] as String? ?? '',
        revoked: j['revokedAt'] != null,
      );
}

enum AssignmentStatus { proposto, accettato, rifiutato, annullato, completato }

class Assignment {
  Assignment({
    required this.id,
    required this.tourId,
    required this.fromGuideId,
    required this.toGuideId,
    this.status = AssignmentStatus.proposto,
  });
  final String id;
  final String tourId;
  final String fromGuideId;
  final String toGuideId;
  AssignmentStatus status;

  factory Assignment.fromJson(Map<String, dynamic> j) => Assignment(
        id: j['id'] as String,
        tourId: j['tourId'] as String,
        fromGuideId: j['fromGuideId'] as String,
        toGuideId: j['toGuideId'] as String,
        status: AssignmentStatus.values.firstWhere(
          (s) => s.name == (j['status'] as String?),
          orElse: () => AssignmentStatus.proposto,
        ),
      );
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.message,
    required this.createdAt,
    this.readAt,
  });
  final String id;
  final String message;
  final DateTime createdAt;
  DateTime? readAt;

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        message: j['message'] as String? ?? '',
        createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
        readAt: j['readAt'] == null
            ? null
            : DateTime.parse(j['readAt'] as String).toLocal(),
      );
}

String fmtDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

String fmtPrice(double p) => '${p.toStringAsFixed(p % 1 == 0 ? 0 : 2)} €';

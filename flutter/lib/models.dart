/// Profili professionali distinti (BRD BR-014D, §13.4).
enum Role { turista, guida, accompagnatore, tourOperator }

extension RoleLabel on Role {
  bool get isProfessional => this != Role.turista;
}

Role roleFromString(String? s) =>
    Role.values.firstWhere((r) => r.name == s, orElse: () => Role.turista);

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
  });
  final String id;
  final String name;
  final String email;
  final Role role;
  final String provider;
  final bool verified;
  final List<String> languages;
  final String bio;
  final bool isAdmin;
  final String city;

  /// Dal profilo pubblico (`GET /guides`, `/tours/:id`): niente email.
  factory Guide.fromPublicJson(Map<String, dynamic> j) => Guide(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        email: '',
        role: roleFromString(j['role'] as String?),
        verified: j['verified'] as bool? ?? false,
        languages:
            (j['languages'] as List?)?.cast<String>() ?? const ['Italiano'],
        bio: j['bio'] as String? ?? '',
        city: j['city'] as String? ?? 'Roma',
      );

  /// Dal proprio profilo (`GET /me`): dati completi.
  factory Guide.fromProfileJson(Map<String, dynamic> j) => Guide(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        role: roleFromString(j['role'] as String?),
        verified: j['verified'] as bool? ?? false,
        languages:
            (j['languages'] as List?)?.cast<String>() ?? const ['Italiano'],
        bio: j['bio'] as String? ?? '',
        provider: j['provider'] as String? ?? 'email',
        isAdmin: j['isAdmin'] as bool? ?? false,
        city: j['city'] as String? ?? 'Roma',
      );
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
    this.accessories = const [],
    this.visits = 0,
    this.scans = 0,
  });
  final String id;
  final String title;
  final String city;
  final String category;
  final String language;
  final String duration;
  final DateTime start;
  final double price;
  final String meetingPoint;
  final String description;
  final int seats;
  final String guideId;
  final List<String> accessories;
  int visits;
  int scans;

  bool get isPackage => accessories.isNotEmpty;
  String get url => 'https://guidatour.it/roma/tour/$id';

  factory Tour.fromJson(Map<String, dynamic> j) => Tour(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        city: j['city'] as String? ?? 'Roma',
        category: j['category'] as String? ?? '',
        language: j['language'] as String? ?? '',
        duration: j['duration'] as String? ?? '',
        start: DateTime.parse(j['start'] as String).toLocal(),
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
  });
  final String? id;
  final String tourId;
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
      );
}

/// Voce del carrello: un tour con il numero di persone da richiedere.
class CartItem {
  CartItem(this.tourId, {this.people = 2});
  final String tourId;
  int people;

  factory CartItem.fromJson(Map<String, dynamic> j) =>
      CartItem(j['tourId'] as String, people: (j['people'] as num).toInt());
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

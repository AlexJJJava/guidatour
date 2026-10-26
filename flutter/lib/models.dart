/// Profili professionali distinti (BRD BR-014D, §13.4).
enum Role { turista, guida, accompagnatore, tourOperator }

extension RoleLabel on Role {
  bool get isProfessional => this != Role.turista;

  String get label => switch (this) {
        Role.turista => 'Turista',
        Role.guida => 'Guida turistica',
        Role.accompagnatore => 'Accompagnatore turistico',
        Role.tourOperator => 'Tour operator',
      };
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
  });
  final String id;
  final String name;
  final String email;
  final Role role;
  final String provider;
  final bool verified;
  final List<String> languages;
  final String bio;
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

class Tour {
  Tour({
    required this.id,
    required this.title,
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
}

class BookingRequest {
  BookingRequest({
    required this.tourId,
    required this.name,
    required this.email,
    required this.phone,
    required this.people,
    required this.message,
    required this.createdAt,
    this.userId,
    this.status = 'Inviata',
  });
  final String tourId;
  final String name;
  final String email;
  final String phone;
  final int people;
  final String message;
  final DateTime createdAt;

  /// Account del turista, se era loggato quando ha inviato la richiesta.
  final String? userId;

  /// 'Inviata' → 'Confermata' o 'Rifiutata' dalla guida.
  String status;
}

/// Voce del carrello: un tour con il numero di persone da richiedere.
class CartItem {
  CartItem(this.tourId, {this.people = 2});
  final String tourId;
  int people;
}

/// Prova del consenso WhatsApp (BR-011D).
class WhatsAppConsent {
  WhatsAppConsent({
    required this.phone,
    required this.at,
    required this.source,
    required this.text,
    required this.sender,
    this.revoked = false,
  });
  final String phone;
  final DateTime at;
  final String source;
  final String text;
  final String sender;
  bool revoked;
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
}

String fmtDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

String fmtPrice(double p) => '${p.toStringAsFixed(p % 1 == 0 ? 0 : 2)} €';

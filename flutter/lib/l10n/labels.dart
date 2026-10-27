import 'package:flutter/widgets.dart';

import '../models.dart';
import 'gen/app_localizations.dart';

/// Etichette localizzate per i valori "di dominio" (ruoli, categorie, lingue,
/// servizi accessori, stati): il valore canonico scambiato con il backend
/// resta sempre in italiano, qui si traduce solo ciò che vede l'utente.
AppLocalizations l10n(BuildContext context) => AppLocalizations.of(context);

String roleLabel(BuildContext context, Role role) {
  final t = l10n(context);
  return switch (role) {
    Role.turista => t.roleTurista,
    Role.guida => t.roleGuida,
    Role.accompagnatore => t.roleAccompagnatore,
    Role.tourOperator => t.roleTourOperator,
  };
}

String categoryLabel(BuildContext context, String category) {
  final t = l10n(context);
  return switch (category) {
    'Visita guidata' => t.categoryVisitaGuidata,
    'Tour a piedi' => t.categoryTourAPiedi,
    'Enogastronomico' => t.categoryEnogastronomico,
    'Bambini e famiglie' => t.categoryBambiniEFamiglie,
    'Serale' => t.categorySerale,
    'Accompagnamento' => t.categoryAccompagnamento,
    _ => category,
  };
}

String cityLabel(BuildContext context, String city) {
  final t = l10n(context);
  return switch (city) {
    'Roma' => t.cityRoma,
    'Milano' => t.cityMilano,
    'Firenze' => t.cityFirenze,
    'Venezia' => t.cityVenezia,
    'Napoli' => t.cityNapoli,
    'Bologna' => t.cityBologna,
    'Torino' => t.cityTorino,
    _ => city,
  };
}

String languageLabel(BuildContext context, String language) {
  final t = l10n(context);
  return switch (language) {
    'Italiano' => t.languageItaliano,
    'English' => t.languageEnglish,
    'Español' => t.languageEspanol,
    'Français' => t.languageFrancais,
    'Deutsch' => t.languageDeutsch,
    _ => language,
  };
}

String accessoryLabel(BuildContext context, String accessory) {
  final t = l10n(context);
  return switch (accessory) {
    'Cena / ristorante' => t.accessoryCenaRistorante,
    'Transfer / auto' => t.accessoryTransferAuto,
    'Biglietti / ingressi' => t.accessoryBigliettiIngressi,
    'Hotel' => t.accessoryHotel,
    'Esperienza food' => t.accessoryEsperienzaFood,
    _ => accessory,
  };
}

/// Stato di una richiesta di prenotazione ('inviata'|'confermata'|'rifiutata').
String requestStatusLabel(BuildContext context, String status) {
  final t = l10n(context);
  return switch (status) {
    'confermata' => t.statusConfermata,
    'rifiutata' => t.statusRifiutata,
    _ => t.statusInviata,
  };
}

/// Stato di una cessione tour tra professionisti.
String assignmentStatusLabel(BuildContext context, AssignmentStatus status) {
  final t = l10n(context);
  return switch (status) {
    AssignmentStatus.proposto => t.statusProposto,
    AssignmentStatus.accettato => t.statusAccettato,
    AssignmentStatus.rifiutato => t.statusRifiutato,
    AssignmentStatus.annullato => t.statusAnnullato,
    AssignmentStatus.completato => t.statusCompletato,
  };
}

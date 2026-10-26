import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'poster_screen.dart';
import 'tour_form_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final user = appState.currentUser;
        if (user == null) return const SizedBox.shrink();
        return DefaultTabController(
          length: 4,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ciao ${user.name}',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: kInk)),
                          Text(
                              '${user.role.label}${user.verified ? ' · verificato' : ' · in attesa di verifica'}',
                              style: const TextStyle(color: kMuted)),
                        ],
                      ),
                    ),
                    TextButton(
                        onPressed: appState.logout, child: const Text('Esci')),
                  ],
                ),
              ),
              const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: 'Panoramica'),
                  Tab(text: 'I miei tour'),
                  Tab(text: 'Assegnazioni'),
                  Tab(text: 'Contatti'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _Overview(user: user),
                    _MyTours(user: user),
                    _Assignments(user: user),
                    _Contacts(user: user),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E8E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kPrimary),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: kInk)),
          Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.user});
  final Guide user;

  @override
  Widget build(BuildContext context) {
    final mine = appState.tours.where((t) => t.guideId == user.id).toList();
    final ids = mine.map((t) => t.id).toSet();
    final reqs = appState.requests.where((r) => ids.contains(r.tourId)).length;
    final visits = mine.fold(0, (s, t) => s + t.visits);
    final scans = mine.fold(0, (s, t) => s + t.scans);
    final alerts = appState.overbookingAlerts(user.id);
    final rate = visits == 0 ? 0 : (reqs * 100 / visits);
    return PageBody(
      maxWidth: 900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 12, runSpacing: 12, children: [
            _StatTile('Tour pubblicati', '${mine.length}', Icons.map_outlined),
            _StatTile('Visite pagina', '$visits', Icons.visibility_outlined),
            _StatTile('Scansioni QR', '$scans', Icons.qr_code_2),
            _StatTile('Richieste', '$reqs', Icons.mail_outline),
            _StatTile('Conversione', '${rate.toStringAsFixed(1)}%',
                Icons.trending_up),
          ]),
          const SizedBox(height: 28),
          const SectionHeading(title: 'Alert disponibilità'),
          const SizedBox(height: 10),
          if (alerts.isEmpty)
            const InfoBanner('Nessuna criticità: posti e orari sono in regola.')
          else
            for (final a in alerts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InfoBanner(a, warning: true),
              ),
          const SizedBox(height: 28),
          const SectionHeading(title: 'Ultime notifiche'),
          const SizedBox(height: 10),
          if (appState.notifications.isEmpty)
            const Text('Nessuna notifica.', style: TextStyle(color: kMuted))
          else
            for (final n in appState.notifications.reversed.take(8))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_none, size: 20),
                title: Text(n, style: const TextStyle(fontSize: 13)),
              ),
        ],
      ),
    );
  }
}

class _MyTours extends StatelessWidget {
  const _MyTours({required this.user});
  final Guide user;

  @override
  Widget build(BuildContext context) {
    final mine = appState.tours.where((t) => t.guideId == user.id).toList();
    return PageBody(
      maxWidth: 900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TourFormScreen())),
            icon: const Icon(Icons.add),
            label: const Text('Nuovo tour'),
          ),
          const SizedBox(height: 16),
          if (mine.isEmpty) const Text('Non hai ancora pubblicato tour.'),
          for (final t in mine)
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFE0E8E3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(
                        '${fmtDate(t.start)} · ${fmtPrice(t.price)} · ${t.seats} posti · '
                        '${t.visits} visite · ${t.scans} scansioni',
                        style: const TextStyle(color: kMuted, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => PosterScreen(tour: t))),
                          icon: const Icon(Icons.qr_code_2, size: 18),
                          label: const Text('QR e locandina'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _propose(context, t),
                          icon: const Icon(Icons.swap_horiz, size: 18),
                          label: const Text('Proponi a un collega'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _propose(BuildContext context, Tour t) async {
    final candidates = appState.guides
        .where((g) => g.id != user.id && g.role == Role.guida)
        .toList();
    final chosen = await showDialog<Guide>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Scegli la guida destinataria'),
        children: [
          if (candidates.isEmpty)
            const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Nessuna guida disponibile.')),
          for (final g in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, g),
              child: Text('${g.name} · ${g.languages.join(', ')}'),
            ),
        ],
      ),
    );
    if (chosen != null && context.mounted) {
      appState.proposeAssignment(t, chosen);
      snack(context, 'Proposta inviata a ${chosen.name}');
    }
  }
}

class _Assignments extends StatelessWidget {
  const _Assignments({required this.user});
  final Guide user;

  @override
  Widget build(BuildContext context) {
    final sent =
        appState.assignments.where((a) => a.fromGuideId == user.id).toList();
    final received =
        appState.assignments.where((a) => a.toGuideId == user.id).toList();
    return PageBody(
      maxWidth: 900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InfoBanner(
              'La guida destinataria può solo accettare o rifiutare: non può riassegnare il tour ad altri.'),
          const SizedBox(height: 20),
          const SectionHeading(title: 'Ricevute'),
          if (received.isEmpty) const Text('Nessuna proposta ricevuta.'),
          for (final a in received)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(appState.tourById(a.tourId)?.title ?? ''),
              subtitle: Text(
                  'Da ${appState.guideById(a.fromGuideId)?.name} · ${a.status.name}'),
              trailing: a.status == AssignmentStatus.proposto
                  ? Wrap(spacing: 4, children: [
                      IconButton(
                        tooltip: 'Rifiuta',
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          appState.respond(a, false);
                          snack(context,
                              'Rifiutato. Notifica inviata alla guida titolare.');
                        },
                      ),
                      IconButton(
                        tooltip: 'Accetta',
                        icon: const Icon(Icons.check, color: kPrimary),
                        onPressed: () {
                          appState.respond(a, true);
                          snack(context,
                              'Accettato. Notifica inviata alla guida titolare.');
                        },
                      ),
                    ])
                  : null,
            ),
          const SizedBox(height: 20),
          const SectionHeading(title: 'Inviate'),
          if (sent.isEmpty) const Text('Nessuna proposta inviata.'),
          for (final a in sent)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(appState.tourById(a.tourId)?.title ?? ''),
              subtitle: Text(
                  'A ${appState.guideById(a.toGuideId)?.name} · ${a.status.name}'),
              trailing: a.status == AssignmentStatus.proposto
                  ? TextButton(
                      onPressed: () => appState.cancelAssignment(a),
                      child: const Text('Annulla'))
                  : null,
            ),
        ],
      ),
    );
  }
}

class _Contacts extends StatelessWidget {
  const _Contacts({required this.user});
  final Guide user;

  @override
  Widget build(BuildContext context) {
    final ids = appState.tours
        .where((t) => t.guideId == user.id)
        .map((t) => t.id)
        .toSet();
    final reqs = appState.requests
        .where((r) => ids.contains(r.tourId))
        .toList()
        .reversed;
    return PageBody(
      maxWidth: 900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(title: 'Richieste di prenotazione'),
          if (reqs.isEmpty) const Text('Nessuna richiesta ricevuta.'),
          for (final r in reqs)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mail_outline),
              title: Text('${r.name} · ${r.people} persone'),
              subtitle: Text('${appState.tourById(r.tourId)?.title}\n${r.email}'
                  '${r.phone.isEmpty ? '' : ' · ${r.phone}'}'
                  '${r.message.isEmpty ? '' : '\n“${r.message}”'}'),
              isThreeLine: true,
              trailing: r.status == 'Inviata'
                  ? Wrap(spacing: 4, children: [
                      IconButton(
                        tooltip: 'Rifiuta',
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () =>
                            appState.setRequestStatus(r, 'Rifiutata'),
                      ),
                      IconButton(
                        tooltip: 'Conferma',
                        icon: const Icon(Icons.check, color: kPrimary),
                        onPressed: () =>
                            appState.setRequestStatus(r, 'Confermata'),
                      ),
                    ])
                  : Text(r.status,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          const SizedBox(height: 24),
          const SectionHeading(title: 'Consensi WhatsApp raccolti'),
          if (appState.consents.isEmpty) const Text('Nessun opt-in raccolto.'),
          for (final c in appState.consents)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                  c.revoked ? Icons.block : Icons.check_circle_outline,
                  color: c.revoked ? Colors.red : kPrimary),
              title: Text(c.phone),
              subtitle:
                  Text('${fmtDate(c.at)} · ${c.source} · mittente: ${c.sender}'
                      '${c.revoked ? ' · REVOCATO' : ''}'),
              trailing: c.revoked
                  ? null
                  : TextButton(
                      onPressed: () => appState.revokeConsent(c),
                      child: const Text('Registra revoca')),
            ),
        ],
      ),
    );
  }
}

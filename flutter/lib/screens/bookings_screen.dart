import 'package:flutter/material.dart';

import '../l10n/labels.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'auth_screen.dart';
import 'tour_detail_screen.dart';

/// Prenotazioni: se non è loggato mostra l'accesso. Da loggato mostra lo
/// storico delle richieste inviate (turista) o quelle ricevute (professionista).
class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final user = appState.currentUser;
        if (user == null) return const AuthScreen();
        return user.role.isProfessional
            ? const _ReceivedBookings()
            : const _SentBookings();
      },
    );
  }
}

/// Richieste inviate dal turista per i propri tour (storico).
class _SentBookings extends StatelessWidget {
  const _SentBookings();

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final reqs = appState.myRequests;
    return PageBody(
      maxWidth: 900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.bookingsTitleSent,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800, color: kInk)),
          const SizedBox(height: 20),
          if (reqs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text(t.historyEmpty)),
            )
          else
            for (final r in reqs)
              Builder(builder: (context) {
                final tour = appState.tourById(r.tourId);
                final color = switch (r.status) {
                  'confermata' => kPrimary,
                  'rifiutata' => Colors.red,
                  _ => kMuted,
                };
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history),
                  title: Text(tour?.title ?? t.tourUnavailable),
                  subtitle: Text(tour == null
                      ? t.historyLine(fmtDate(r.createdAt), r.people)
                      : t.historyLineWithTourDate(
                          fmtDate(r.createdAt), r.people, fmtDate(tour.start))),
                  trailing: Text(requestStatusLabel(context, r.status),
                      style:
                          TextStyle(color: color, fontWeight: FontWeight.w700)),
                  onTap: tour == null ? null : () => openTour(context, tour),
                );
              }),
        ],
      ),
    );
  }
}

/// Richieste ricevute dal professionista per i propri tour.
class _ReceivedBookings extends StatelessWidget {
  const _ReceivedBookings();

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final reqs = appState.requests.reversed.toList();
    return PageBody(
      maxWidth: 900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.bookingsTitleReceived,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800, color: kInk)),
          const SizedBox(height: 20),
          if (reqs.isEmpty) Text(t.noRequestsReceived),
          for (final r in reqs)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mail_outline),
              title: Text(t.nameAndPeople(r.name, r.people)),
              subtitle: Text('${appState.tourById(r.tourId)?.title}\n${r.email}'
                  '${r.phone.isEmpty ? '' : ' · ${r.phone}'}'
                  '${r.message.isEmpty ? '' : '\n“${r.message}”'}'),
              isThreeLine: true,
              trailing: r.status == 'inviata'
                  ? Wrap(spacing: 4, children: [
                      IconButton(
                        tooltip: t.reject,
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => runOrSnack(context,
                            () => appState.setRequestStatus(r, 'rifiutata')),
                      ),
                      IconButton(
                        tooltip: t.confirm,
                        icon: const Icon(Icons.check, color: kPrimary),
                        onPressed: () => runOrSnack(context,
                            () => appState.setRequestStatus(r, 'confermata')),
                      ),
                    ])
                  : Text(requestStatusLabel(context, r.status),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

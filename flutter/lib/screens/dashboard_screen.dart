import 'package:flutter/material.dart';

import '../l10n/labels.dart';
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
        final t = l10n(context);
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
                          Text(t.greetingHello(user.name),
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: kInk)),
                          Text(
                              '${roleLabel(context, user.role)}'
                              '${user.verified ? ' · ${t.verifiedSuffix}' : ' · ${t.unverifiedSuffix}'}',
                              style: const TextStyle(color: kMuted)),
                        ],
                      ),
                    ),
                    TextButton(
                        onPressed: appState.logout, child: Text(t.logout)),
                  ],
                ),
              ),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: t.dashTabOverview),
                  Tab(text: t.dashTabMyTours),
                  Tab(text: t.dashTabAssignments),
                  Tab(text: t.dashTabContacts),
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
    final t = l10n(context);
    final mine = appState.tours.where((tour) => tour.guideId == user.id).toList();
    final ids = mine.map((tour) => tour.id).toSet();
    final reqs = appState.requests.where((r) => ids.contains(r.tourId)).length;
    final visits = mine.fold(0, (s, tour) => s + tour.visits);
    final scans = mine.fold(0, (s, tour) => s + tour.scans);
    final alerts = appState.overbookingAlerts(user.id);
    final rate = visits == 0 ? 0 : (reqs * 100 / visits);
    return PageBody(
      maxWidth: 900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 12, runSpacing: 12, children: [
            _StatTile(t.statToursPublished, '${mine.length}', Icons.map_outlined),
            _StatTile(t.statPageViews, '$visits', Icons.visibility_outlined),
            _StatTile(t.statQrScans, '$scans', Icons.qr_code_2),
            _StatTile(t.statRequests, '$reqs', Icons.mail_outline),
            _StatTile(t.statConversion, '${rate.toStringAsFixed(1)}%',
                Icons.trending_up),
          ]),
          const SizedBox(height: 28),
          SectionHeading(title: t.dashAlertsTitle),
          const SizedBox(height: 10),
          if (alerts.isEmpty)
            InfoBanner(t.dashNoAlerts)
          else
            for (final a in alerts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InfoBanner(a, warning: true),
              ),
          const SizedBox(height: 28),
          SectionHeading(title: t.dashNotificationsTitle),
          const SizedBox(height: 10),
          if (appState.notifications.isEmpty)
            Text(t.dashNoNotifications, style: const TextStyle(color: kMuted))
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
    final t = l10n(context);
    final mine = appState.tours.where((tour) => tour.guideId == user.id).toList();
    return PageBody(
      maxWidth: 900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TourFormScreen())),
            icon: const Icon(Icons.add),
            label: Text(t.newTour),
          ),
          const SizedBox(height: 16),
          if (mine.isEmpty) Text(t.dashNoToursYet),
          for (final tour in mine)
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
                    Text(tour.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(
                        t.dashTourLine(fmtDate(tour.start), fmtPrice(tour.price),
                            tour.seats, tour.visits, tour.scans),
                        style: const TextStyle(color: kMuted, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => PosterScreen(tour: tour))),
                          icon: const Icon(Icons.qr_code_2, size: 18),
                          label: Text(t.qrAndPoster),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _propose(context, tour),
                          icon: const Icon(Icons.swap_horiz, size: 18),
                          label: Text(t.proposeToColleague),
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

  Future<void> _propose(BuildContext context, Tour tour) async {
    final t = l10n(context);
    final candidates = appState.guides
        .where((g) => g.id != user.id && g.role == Role.guida)
        .toList();
    final chosen = await showDialog<Guide>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(t.chooseRecipientGuide),
        children: [
          if (candidates.isEmpty)
            Padding(
                padding: const EdgeInsets.all(20),
                child: Text(t.noGuideAvailable)),
          for (final g in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, g),
              child: Text('${g.name} · ${g.languages.map((l) => languageLabel(context, l)).join(', ')}'),
            ),
        ],
      ),
    );
    if (chosen == null) return;
    try {
      await appState.proposeAssignment(tour, chosen);
      if (context.mounted) snack(context, t.proposalSentTo(chosen.name));
    } catch (e) {
      if (context.mounted) snack(context, '$e');
    }
  }
}

class _Assignments extends StatelessWidget {
  const _Assignments({required this.user});
  final Guide user;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final sent =
        appState.assignments.where((a) => a.fromGuideId == user.id).toList();
    final received =
        appState.assignments.where((a) => a.toGuideId == user.id).toList();
    return PageBody(
      maxWidth: 900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoBanner(t.assignmentInfoBanner),
          const SizedBox(height: 20),
          SectionHeading(title: t.received),
          if (received.isEmpty) Text(t.noProposalsReceived),
          for (final a in received)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(appState.tourById(a.tourId)?.title ?? ''),
              subtitle: Text(t.fromGuideStatus(
                  appState.guideById(a.fromGuideId)?.name ?? '',
                  assignmentStatusLabel(context, a.status))),
              trailing: a.status == AssignmentStatus.proposto
                  ? Wrap(spacing: 4, children: [
                      IconButton(
                        tooltip: t.reject,
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          try {
                            await appState.respond(a, false);
                            if (context.mounted) {
                              snack(context, t.rejectedNotified);
                            }
                          } catch (e) {
                            if (context.mounted) snack(context, '$e');
                          }
                        },
                      ),
                      IconButton(
                        tooltip: t.accept,
                        icon: const Icon(Icons.check, color: kPrimary),
                        onPressed: () async {
                          try {
                            await appState.respond(a, true);
                            if (context.mounted) {
                              snack(context, t.acceptedNotified);
                            }
                          } catch (e) {
                            if (context.mounted) snack(context, '$e');
                          }
                        },
                      ),
                    ])
                  : null,
            ),
          const SizedBox(height: 20),
          SectionHeading(title: t.sent),
          if (sent.isEmpty) Text(t.noProposalsSent),
          for (final a in sent)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(appState.tourById(a.tourId)?.title ?? ''),
              subtitle: Text(t.toGuideStatus(
                  appState.guideById(a.toGuideId)?.name ?? '',
                  assignmentStatusLabel(context, a.status))),
              trailing: a.status == AssignmentStatus.proposto
                  ? TextButton(
                      onPressed: () async {
                        try {
                          await appState.cancelAssignment(a);
                        } catch (e) {
                          if (context.mounted) snack(context, '$e');
                        }
                      },
                      child: Text(t.cancel))
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
    final t = l10n(context);
    final ids = appState.tours
        .where((tour) => tour.guideId == user.id)
        .map((tour) => tour.id)
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
          SectionHeading(title: t.bookingRequestsTitle),
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
                        onPressed: () async {
                          try {
                            await appState.setRequestStatus(r, 'rifiutata');
                          } catch (e) {
                            if (context.mounted) snack(context, '$e');
                          }
                        },
                      ),
                      IconButton(
                        tooltip: t.confirm,
                        icon: const Icon(Icons.check, color: kPrimary),
                        onPressed: () async {
                          try {
                            await appState.setRequestStatus(r, 'confermata');
                          } catch (e) {
                            if (context.mounted) snack(context, '$e');
                          }
                        },
                      ),
                    ])
                  : Text(requestStatusLabel(context, r.status),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          const SizedBox(height: 24),
          SectionHeading(title: t.whatsappConsentsTitle),
          if (appState.consents.isEmpty) Text(t.noOptins),
          for (final c in appState.consents)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                  c.revoked ? Icons.block : Icons.check_circle_outline,
                  color: c.revoked ? Colors.red : kPrimary),
              title: Text(c.phone),
              subtitle: Text(
                  '${t.consentLine(fmtDate(c.at), c.source, c.sender)}'
                  '${c.revoked ? ' · ${t.revokedSuffix}' : ''}'),
              trailing: c.revoked
                  ? null
                  : TextButton(
                      onPressed: () async {
                        try {
                          await appState.revokeConsent(c);
                        } catch (e) {
                          if (context.mounted) snack(context, '$e');
                        }
                      },
                      child: Text(t.registerRevoke)),
            ),
        ],
      ),
    );
  }
}

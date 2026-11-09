import 'package:flutter/material.dart';

import '../l10n/labels.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'auth_screen.dart';

/// Cambio / cessione tour tra professionisti (BR-011A).
class AssignmentsScreen extends StatelessWidget {
  const AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final user = appState.currentUser;
        if (user == null) return const AuthScreen();
        final t = l10n(context);
        final sent = appState.assignments
            .where((a) => a.fromGuideId == user.id)
            .toList();
        final received =
            appState.assignments.where((a) => a.toGuideId == user.id).toList();
        return PageBody(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                  title: t.dashTabAssignments,
                  icon: Icons.swap_horiz,
                  subtitle: t.pageAssignmentsSub),
              const SizedBox(height: 16),
              InfoBanner(t.assignmentInfoBanner),
              const SizedBox(height: 20),
              SectionHeading(title: t.received),
              if (received.isEmpty)
                EmptyState(
                    icon: Icons.move_to_inbox_outlined,
                    message: t.noProposalsReceived),
              for (final a in received)
                _AssignmentCard(
                  tour: appState.tourById(a.tourId),
                  status: a.status,
                  who: appState.guideById(a.fromGuideId)?.name ?? '',
                  incoming: true,
                  actions: a.status == AssignmentStatus.proposto
                      ? Wrap(spacing: 4, children: [
                          IconButton(
                            tooltip: t.reject,
                            icon: const Icon(Icons.close, color: kDanger),
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
              if (sent.isEmpty)
                EmptyState(
                    icon: Icons.outbox_outlined, message: t.noProposalsSent),
              for (final a in sent)
                _AssignmentCard(
                  tour: appState.tourById(a.tourId),
                  status: a.status,
                  who: appState.guideById(a.toGuideId)?.name ?? '',
                  incoming: false,
                  actions: a.status == AssignmentStatus.proposto
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
      },
    );
  }
}

/// Proposta di cessione: tour, collega, stato e azioni.
class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.tour,
    required this.status,
    required this.who,
    required this.incoming,
    required this.actions,
  });
  final Tour? tour;
  final AssignmentStatus status;
  final String who;
  final bool incoming;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final label = assignmentStatusLabel(context, status);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(kRadiusSm),
              child: tour == null
                  ? Container(width: 56, height: 56, color: kSand)
                  : Image.asset(tourImage(tour!),
                      width: 56, height: 56, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tour?.title ?? t.tourUnavailable,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(incoming ? Icons.call_received : Icons.call_made,
                          size: 16, color: kPrimary),
                      const SizedBox(width: 4),
                      Flexible(
                          child: Text(who,
                              style: const TextStyle(
                                  color: kMuted, fontSize: 13))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            actions ??
                StatusPill(label,
                    tone: switch (status) {
                      AssignmentStatus.accettato ||
                      AssignmentStatus.completato =>
                        PillTone.ok,
                      AssignmentStatus.rifiutato ||
                      AssignmentStatus.annullato =>
                        PillTone.alert,
                      _ => PillTone.waiting,
                    }),
          ],
        ),
      ),
    );
  }
}

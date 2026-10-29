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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.dashTabAssignments,
                  style: const TextStyle(
                      fontFamily: kSerif,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: kInk)),
              const SizedBox(height: 16),
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
      },
    );
  }
}

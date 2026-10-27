import 'package:flutter/material.dart';

import '../l10n/labels.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'auth_screen.dart';

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

/// Panoramica del professionista: statistiche, alert, notifiche e (per gli
/// admin) i consensi WhatsApp raccolti.
class DashboardOverviewScreen extends StatelessWidget {
  const DashboardOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final user = appState.currentUser;
        if (user == null) return const AuthScreen();
        final t = l10n(context);
        final mine =
            appState.myTours.where((tour) => tour.guideId == user.id).toList();
        final ids = mine.map((tour) => tour.id).toSet();
        final reqs =
            appState.requests.where((r) => ids.contains(r.tourId)).length;
        final visits = mine.fold(0, (s, tour) => s + tour.visits);
        final scans = mine.fold(0, (s, tour) => s + tour.scans);
        final alerts = appState.overbookingAlerts(user.id);
        final rate = visits == 0 ? 0 : (reqs * 100 / visits);
        return PageBody(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.dashTabOverview,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800, color: kInk)),
              const SizedBox(height: 20),
              Wrap(spacing: 12, runSpacing: 12, children: [
                _StatTile(
                    t.statToursPublished, '${mine.length}', Icons.map_outlined),
                _StatTile(
                    t.statPageViews, '$visits', Icons.visibility_outlined),
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
              Row(
                children: [
                  Expanded(
                      child: SectionHeading(title: t.dashNotificationsTitle)),
                  if (appState.notifications.any((n) => !n.isRead))
                    TextButton(
                      onPressed: () => runOrSnack(
                          context, appState.markAllNotificationsRead),
                      child: Text(t.markAllRead),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (appState.notifications.isEmpty)
                Text(t.dashNoNotifications,
                    style: const TextStyle(color: kMuted))
              else
                for (final n in appState.notifications.take(8))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                        n.isRead ? Icons.notifications_none : Icons.circle,
                        size: n.isRead ? 20 : 10,
                        color: n.isRead ? null : kPrimary),
                    title: Text(n.message,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: n.isRead
                                ? FontWeight.normal
                                : FontWeight.w700)),
                    trailing: n.isRead
                        ? null
                        : IconButton(
                            tooltip: t.markRead,
                            icon: const Icon(Icons.check, size: 18),
                            onPressed: () => runOrSnack(context,
                                () => appState.markNotificationRead(n)),
                          ),
                  ),
              if (appState.consents.isNotEmpty) ...[
                const SizedBox(height: 28),
                SectionHeading(title: t.whatsappConsentsTitle),
                const SizedBox(height: 10),
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
                            onPressed: () => runOrSnack(
                                context, () => appState.revokeConsent(c)),
                            child: Text(t.registerRevoke)),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

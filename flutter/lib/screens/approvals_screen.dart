import 'package:flutter/material.dart';

import '../l10n/labels.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';

/// Scheda della Gestione: tutte le registrazioni professionali, dalla più
/// recente, con data e stato; i filtri restringono a in attesa, approvate o
/// rifiutate. Finché non sono approvati gli utenti sono turisti.
class ApprovalsPanel extends StatefulWidget {
  const ApprovalsPanel({super.key});

  @override
  State<ApprovalsPanel> createState() => _ApprovalsPanelState();
}

class _ApprovalsPanelState extends State<ApprovalsPanel> {
  String _status = 'tutte';
  late Future<List<Guide>> _future = appState.loadRegistrations(_status);

  void _reload() =>
      setState(() => _future = appState.loadRegistrations(_status));

  Future<void> _decide(Guide g, String status) async {
    final t = l10n(context);
    await runOrSnack(context, () async {
      await appState.decideRegistration(g.id, status);
      if (!mounted) return;
      snack(
          context,
          status == 'approvato'
              ? t.approvalsApprovedDone(g.name)
              : t.approvalsRejectedDone(g.name));
    });
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.approvalsIntro, style: const TextStyle(color: kMuted)),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'tutte', label: Text(t.approvalsAll)),
                ButtonSegment(
                    value: 'in_attesa', label: Text(t.approvalsPending)),
                ButtonSegment(
                    value: 'approvato', label: Text(t.approvalsApproved)),
                ButtonSegment(
                    value: 'rifiutato', label: Text(t.approvalsRejected)),
              ],
              selected: {_status},
              showSelectedIcon: false,
              onSelectionChanged: (s) {
                _status = s.first;
                _reload();
              },
            ),
          ),
        ),
        const SizedBox(height: 18),
        FutureBuilder<List<Guide>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child:
                    Center(child: CircularProgressIndicator(color: kPrimary)),
              );
            }
            if (snap.hasError) {
              return InfoBanner('${snap.error}', warning: true);
            }
            // Dalla registrazione più recente.
            final list = [...snap.data!]..sort((a, b) =>
                (b.createdAt ?? DateTime(0))
                    .compareTo(a.createdAt ?? DateTime(0)));
            if (list.isEmpty) {
              return EmptyState(
                  icon: Icons.how_to_reg_outlined, message: t.approvalsEmpty);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final g in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RegistrationCard(
                      guide: g,
                      // Chi è già approvato e chiede nuovi ruoli si può
                      // approvare (i ruoli si sommano) o rifiutare (restano
                      // quelli che ha).
                      onApprove: g.approvalStatus != 'approvato' ||
                              g.pendingRoles.isNotEmpty
                          ? () => _decide(g, 'approvato')
                          : null,
                      onReject: g.approvalStatus != 'rifiutato'
                          ? () => _decide(g, 'rifiutato')
                          : null,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Stato della richiesta: chi chiede nuovi ruoli è "in attesa" anche se il
/// suo account è già approvato.
(String, PillTone) approvalStatusLabel(BuildContext context, Guide g) {
  final t = l10n(context);
  if (g.pendingRoles.isNotEmpty) {
    return (t.approvalStatusPending, PillTone.waiting);
  }
  return switch (g.approvalStatus) {
    'approvato' => (t.approvalStatusApproved, PillTone.ok),
    'rifiutato' => (t.approvalStatusRejected, PillTone.alert),
    'sospeso' => (t.approvalStatusSuspended, PillTone.alert),
    _ => (t.approvalStatusPending, PillTone.waiting),
  };
}

class _RegistrationCard extends StatelessWidget {
  const _RegistrationCard(
      {required this.guide, required this.onApprove, required this.onReject});
  final Guide guide;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final (status, tone) = approvalStatusLabel(context, guide);
    final details = [
      rolesLabel(context,
          guide.requestedRoles.isEmpty ? guide.roles : guide.requestedRoles),
      if (guide.pendingRoles.isNotEmpty)
        t.approvalsAddsRoles(rolesLabel(context, guide.pendingRoles)),
      guide.email,
      cityLabel(context, guide.city),
    ];
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(guide.name.isEmpty ? guide.email : guide.name,
                style: const TextStyle(
                    fontFamily: kSerif,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kInk)),
            StatusPill(status, tone: tone, key: ValueKey('status-${guide.id}')),
          ],
        ),
        const SizedBox(height: 4),
        Text(details.join(' · '),
            style: const TextStyle(fontSize: 13, color: kMuted)),
        if (guide.createdAt != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 16, color: kPrimary),
              const SizedBox(width: 6),
              Text(t.approvalsRegisteredOn(fmtDate(guide.createdAt!)),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
            ],
          ),
        ],
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onReject != null)
          OutlinedButton(onPressed: onReject, child: Text(t.approvalsReject)),
        if (onReject != null && onApprove != null) const SizedBox(width: 8),
        if (onApprove != null)
          FilledButton(onPressed: onApprove, child: Text(t.approvalsApprove)),
      ],
    );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, c) => c.maxWidth >= 560
              ? Row(
                  children: [
                    Expanded(child: info),
                    const SizedBox(width: 12),
                    actions,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [info, const SizedBox(height: 12), actions],
                ),
        ),
      ),
    );
  }
}

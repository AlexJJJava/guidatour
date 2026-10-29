import 'package:flutter/material.dart';

import '../l10n/labels.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';

/// Solo admin: approva o rifiuta le registrazioni di guide, accompagnatori e
/// tour operator. Finché non sono approvati non possono accedere.
class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  String _status = 'in_attesa';
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
    return PageBody(
      maxWidth: 860,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.approvalsTitle,
              style: const TextStyle(
                  fontFamily: kSerif,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: kInk)),
          const SizedBox(height: 6),
          Text(t.approvalsIntro, style: const TextStyle(color: kMuted)),
          const SizedBox(height: 18),
          SegmentedButton<String>(
            segments: [
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
              final list = snap.data!;
              if (list.isEmpty) {
                return EmptyState(
                    icon: Icons.how_to_reg_outlined, message: t.approvalsEmpty);
              }
              return Column(
                children: [
                  for (final g in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RegistrationCard(
                        guide: g,
                        onApprove: g.approvalStatus == 'approvato'
                            ? null
                            : () => _decide(g, 'approvato'),
                        onReject: g.approvalStatus == 'rifiutato'
                            ? null
                            : () => _decide(g, 'rifiutato'),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
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
    final details = [
      roleLabel(context, guide.role),
      guide.email,
      cityLabel(context, guide.city),
      if (guide.createdAt != null)
        t.approvalsRegisteredOn(fmtDate(guide.createdAt!)),
    ];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 260, maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(guide.name.isEmpty ? guide.email : guide.name,
                      style: const TextStyle(
                          fontFamily: kSerif,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: kInk)),
                  const SizedBox(height: 4),
                  Text(details.join(' · '),
                      style: const TextStyle(fontSize: 13, color: kMuted)),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onReject != null)
                  OutlinedButton(
                      onPressed: onReject, child: Text(t.approvalsReject)),
                if (onReject != null && onApprove != null)
                  const SizedBox(width: 8),
                if (onApprove != null)
                  FilledButton(
                      onPressed: onApprove, child: Text(t.approvalsApprove)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

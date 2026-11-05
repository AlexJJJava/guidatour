import 'package:flutter/material.dart';

import '../l10n/labels.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'approvals_screen.dart';
import 'tour_detail_screen.dart';

/// Area di gestione dell'admin: panoramica, professionisti, tour,
/// approvazioni e consensi WhatsApp (BR-009, BR-011D).
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final tabs = [
      (t.adminTabOverview, Icons.insights_outlined),
      (t.adminTabProfessionals, Icons.badge_outlined),
      (t.adminTabTours, Icons.map_outlined),
      (t.adminTabApprovals, Icons.how_to_reg_outlined),
      (t.adminTabWhatsapp, Icons.chat_bubble_outline),
    ];
    return PageBody(
      maxWidth: 1080,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _AdminHeader(),
          const SizedBox(height: 18),
          ListenableBuilder(
            listenable: appState,
            builder: (context, _) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < tabs.length; i++)
                  _TabPill(
                    key: ValueKey('admin-tab-$i'),
                    label: tabs[i].$1,
                    icon: tabs[i].$2,
                    selected: i == _tab,
                    badge: i == 3 ? appState.pendingRegistrations : 0,
                    onTap: () => setState(() => _tab = i),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          switch (_tab) {
            0 => _OverviewTab(onOpenTab: (i) => setState(() => _tab = i)),
            1 => const _ProfessionalsTab(),
            2 => const _ToursTab(),
            3 => const ApprovalsPanel(),
            _ => const _ConsentsTab(),
          },
        ],
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader();

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kRadius),
        gradient: LinearGradient(
          colors: [kGold.withValues(alpha: 0.75), kSand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration:
                const BoxDecoration(color: kNight, shape: BoxShape.circle),
            child: const Icon(Icons.admin_panel_settings_outlined,
                color: kGold, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.adminTitle,
                    style: const TextStyle(
                        fontFamily: kSerif,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: kInk)),
                const SizedBox(height: 4),
                Text(t.adminSubtitle,
                    style: const TextStyle(color: kInk, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? kOnGold : kInk;
    return Material(
      color: selected ? kGold : kSurface,
      shape: StadiumBorder(side: BorderSide(color: selected ? kGold : kLine)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: fg,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500)),
              if (badge > 0) ...[
                const SizedBox(width: 8),
                Badge(label: Text('$badge')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Riquadro numerico: il bordo dorato a sinistra lo lega al tema.
class _AdminStat extends StatelessWidget {
  const _AdminStat(this.label, this.value, this.icon,
      {this.highlight = false, this.onTap});
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _tile);

  /// Griglia regolare: tre per riga su schermo largo, due su telefono, tutti
  /// alti uguali anche con le etichette su due righe.
  Widget _tile(BuildContext context, BoxConstraints c) {
    const gap = 12.0;
    final cols = c.maxWidth >= 700 ? 3 : 2;
    return SizedBox(
      width: (c.maxWidth - gap * (cols - 1)) / cols,
      height: MediaQuery.textScalerOf(context).scale(84),
      child: Material(
        color: highlight ? kGold.withValues(alpha: 0.3) : kSurface,
        borderRadius: BorderRadius.circular(kRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadius),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kRadius),
              border: Border(
                left: const BorderSide(color: kGold, width: 4),
                top: BorderSide(color: kLine),
                right: BorderSide(color: kLine),
                bottom: BorderSide(color: kLine),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                      color: kGold.withValues(alpha: 0.25),
                      shape: BoxShape.circle),
                  child: Icon(icon, color: kPrimary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: kInk)),
                      Text(label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: kMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _loading() => const Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: CircularProgressIndicator(color: kPrimary)),
    );

class _OverviewTab extends StatefulWidget {
  const _OverviewTab({required this.onOpenTab});
  final ValueChanged<int> onOpenTab;

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  final _future = appState.loadAdminOverview();

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return _loading();
        if (snap.hasError) return InfoBanner('${snap.error}', warning: true);
        final o = snap.data!;
        String n(String k) => o[k] == null ? '—' : '${o[k]}';
        final upcoming = [...appState.tours]
          ..sort((a, b) => a.start.compareTo(b.start));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _AdminStat(t.adminStatActive, n('professionals'),
                    Icons.verified_outlined,
                    onTap: () => widget.onOpenTab(1)),
                _AdminStat(t.adminStatPending, n('pending'),
                    Icons.hourglass_top_outlined,
                    highlight: (o['pending'] ?? 0) > 0,
                    onTap: () => widget.onOpenTab(3)),
                _AdminStat(
                    t.adminStatSuspended, n('suspended'), Icons.block_outlined,
                    onTap: () => widget.onOpenTab(1)),
                _AdminStat(
                    t.adminStatTourists, n('tourists'), Icons.person_outline),
                _AdminStat(t.adminStatUpcoming, n('upcomingTours'),
                    Icons.event_available_outlined,
                    onTap: () => widget.onOpenTab(2)),
                _AdminStat(t.adminStatTours, n('tours'), Icons.map_outlined,
                    onTap: () => widget.onOpenTab(2)),
                _AdminStat(
                    t.adminStatRequests, n('requests'), Icons.mail_outline),
                _AdminStat(t.adminStatViews, '${n('visits')} · ${n('scans')}',
                    Icons.qr_code_2),
                _AdminStat(t.adminStatConsents, n('consents'),
                    Icons.chat_bubble_outline,
                    onTap: () => widget.onOpenTab(4)),
              ],
            ),
            const SizedBox(height: 28),
            SectionHeading(title: t.adminUpcomingTitle),
            const SizedBox(height: 10),
            if (upcoming.isEmpty)
              EmptyState(icon: Icons.map_outlined, message: t.adminNoTours)
            else
              for (final tour in upcoming.take(5)) _TourRow(tour: tour),
          ],
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: l10n(context).adminSearch,
          filled: true,
          fillColor: kSurface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kRadius),
              borderSide: const BorderSide(color: kLine)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kRadius),
              borderSide: const BorderSide(color: kLine)),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.label, {this.alert = false});
  final String label;
  final bool alert;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: alert ? const Color(0xFFFBE3E1) : kGold.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: alert ? const Color(0xFFA32A20) : kOnGold)),
      );
}

class _ProfessionalsTab extends StatefulWidget {
  const _ProfessionalsTab();

  @override
  State<_ProfessionalsTab> createState() => _ProfessionalsTabState();
}

class _ProfessionalsTabState extends State<_ProfessionalsTab> {
  late Future<List<(Guide, int)>> _future = appState.loadAdminProfessionals();
  String _query = '';

  Future<void> _toggle(Guide g) async {
    final t = l10n(context);
    final suspend = g.approvalStatus == 'approvato';
    if (suspend) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.adminSuspendTitle(g.name)),
          content: Text(t.adminSuspendBody),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(t.cancel)),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t.adminSuspend),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    await runOrSnack(context, () async {
      await appState.setSuspended(g.id, suspend);
      if (!mounted) return;
      snack(
          context,
          suspend
              ? t.adminSuspendedDone(g.name)
              : t.adminReactivatedDone(g.name));
    });
    if (mounted) {
      setState(() => _future = appState.loadAdminProfessionals());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SearchField(
            onChanged: (v) => setState(() => _query = v.toLowerCase())),
        const SizedBox(height: 14),
        FutureBuilder<List<(Guide, int)>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return _loading();
            if (snap.hasError)
              return InfoBanner('${snap.error}', warning: true);
            final list = snap.data!
                .where((e) =>
                    _query.isEmpty ||
                    e.$1.name.toLowerCase().contains(_query) ||
                    e.$1.email.toLowerCase().contains(_query))
                .toList();
            if (list.isEmpty) {
              return EmptyState(
                  icon: Icons.badge_outlined, message: t.adminNoProfessionals);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (g, tours) in list)
                  _ProCard(guide: g, tours: tours, onToggle: () => _toggle(g)),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProCard extends StatelessWidget {
  const _ProCard(
      {required this.guide, required this.tours, required this.onToggle});
  final Guide guide;
  final int tours;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final suspended = guide.approvalStatus == 'sospeso';
    final roles =
        guide.requestedRoles.isEmpty ? guide.roles : guide.requestedRoles;
    final action = suspended
        ? FilledButton.icon(
            onPressed: onToggle,
            icon: const Icon(Icons.play_arrow, size: 18),
            label: Text(t.adminReactivate))
        : OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: onToggle,
            icon: const Icon(Icons.block, size: 18),
            label: Text(t.adminSuspend));
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: _CardRow(
          action: action,
          info: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              UserAvatar(user: guide, radius: 24),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(guide.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        _StatusChip(
                            suspended ? t.adminSuspended : t.adminActive,
                            alert: suspended),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(rolesLabel(context, roles),
                        style: const TextStyle(color: kPrimary)),
                    Text(
                        '${guide.email} · ${cityLabel(context, guide.city)}'
                        ' · ${t.adminToursCount(tours)}',
                        style: const TextStyle(color: kMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dati a sinistra e azioni a destra; su schermo stretto le azioni vanno sotto.
class _CardRow extends StatelessWidget {
  const _CardRow({required this.info, required this.action});
  final Widget info;
  final Widget action;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => c.maxWidth >= 560
            ? Row(
                children: [
                  Expanded(child: info),
                  const SizedBox(width: 12),
                  action,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [info, const SizedBox(height: 10), action],
              ),
      );
}

class _TourRow extends StatelessWidget {
  const _TourRow({required this.tour, this.organizer, this.onDelete});
  final Tour tour;
  final String? organizer;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final past = tour.start.isBefore(DateTime.now());
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _CardRow(
          info: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(categoryImage(tour.category),
                    width: 56, height: 56, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(tour.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        if (past) _StatusChip(t.adminPast),
                      ],
                    ),
                    Text(
                        '${fmtDate(tour.start)} · ${categoryLabel(context, tour.category)}'
                        '${organizer == null ? '' : ' · $organizer'}',
                        style: const TextStyle(color: kMuted, fontSize: 12)),
                    Text(t.adminViewsValue('${tour.visits}', '${tour.scans}'),
                        style: const TextStyle(color: kMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          action: Wrap(
            spacing: 8,
            children: [
              if (!past)
                OutlinedButton(
                    onPressed: () => openTour(context, tour),
                    child: Text(t.adminOpen)),
              if (onDelete != null)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(t.deleteTour),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToursTab extends StatefulWidget {
  const _ToursTab();

  @override
  State<_ToursTab> createState() => _ToursTabState();
}

class _ToursTabState extends State<_ToursTab> {
  late Future<List<AdminTour>> _future = appState.loadAdminTours();
  String _query = '';

  Future<void> _delete(Tour tour) async {
    final t = l10n(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.adminDeleteTourTitle(tour.title)),
        content: Text(t.adminDeleteTourBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.deleteTour),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await runOrSnack(context, () async {
      await appState.adminDeleteTour(tour.id);
      if (mounted) snack(context, t.adminTourDeleted);
    });
    if (mounted) setState(() => _future = appState.loadAdminTours());
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SearchField(
            onChanged: (v) => setState(() => _query = v.toLowerCase())),
        const SizedBox(height: 14),
        FutureBuilder<List<AdminTour>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return _loading();
            if (snap.hasError)
              return InfoBanner('${snap.error}', warning: true);
            final list = snap.data!
                .where((e) =>
                    _query.isEmpty ||
                    e.tour.title.toLowerCase().contains(_query) ||
                    e.guideName.toLowerCase().contains(_query))
                .toList();
            if (list.isEmpty) {
              return EmptyState(
                  icon: Icons.map_outlined, message: t.adminNoTours);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final e in list)
                  _TourRow(
                    tour: e.tour,
                    organizer: e.guideStatus == 'sospeso'
                        ? '${e.guideName} (${t.adminSuspended.toLowerCase()})'
                        : e.guideName,
                    onDelete: () => _delete(e.tour),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ConsentsTab extends StatefulWidget {
  const _ConsentsTab();

  @override
  State<_ConsentsTab> createState() => _ConsentsTabState();
}

class _ConsentsTabState extends State<_ConsentsTab> {
  final _future = appState.loadConsents();

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return _loading();
        if (snap.hasError) return InfoBanner('${snap.error}', warning: true);
        return ListenableBuilder(
          listenable: appState,
          builder: (context, _) {
            if (appState.consents.isEmpty) {
              return EmptyState(
                  icon: Icons.chat_bubble_outline, message: t.adminNoConsents);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final c in appState.consents)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Icon(
                          c.revoked ? Icons.block : Icons.check_circle_outline,
                          color: c.revoked ? Colors.red : kPrimary),
                      title: Text(c.phone,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
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
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

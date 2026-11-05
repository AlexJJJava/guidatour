import 'package:flutter/material.dart';

import '../l10n/labels.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'auth_screen.dart';
import 'profile_edit_screen.dart';

/// Account: se non loggato mostra l'accesso, altrimenti il profilo con i
/// numeri principali, i dati e le azioni sull'account.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final user = appState.currentUser;
        if (user == null) return const AuthScreen();
        final t = l10n(context);
        final pro = user.role.isProfessional;
        void edit() => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileEditScreen()));
        return PageBody(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileHeader(user: user, onEdit: edit),
              if (user.requestedRoles.isNotEmpty) ...[
                const SizedBox(height: 16),
                InfoBanner(
                  key: const ValueKey('requested-role'),
                  switch (user.approvalStatus) {
                    'rifiutato' => t.accountRoleRejected(
                        rolesLabel(context, user.requestedRoles)),
                    'sospeso' => t.accountRoleSuspended(
                        rolesLabel(context, user.requestedRoles)),
                    _ => t.accountRolePending(
                        rolesLabel(context, user.requestedRoles)),
                  },
                  warning: user.approvalStatus != 'in_attesa',
                ),
              ],
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: pro
                    ? [
                        _Count(t.accountStatTours, appState.myTours.length,
                            Icons.map_outlined),
                        _Count(t.accountStatReceived,
                            appState.requests.length, Icons.inbox_outlined),
                        _Count(t.accountStatAssignments,
                            appState.assignments.length, Icons.swap_horiz),
                      ]
                    : [
                        _Count(t.accountStatFavorites,
                            appState.favoriteTours.length,
                            Icons.favorite_border),
                        _Count(t.accountStatRequests,
                            appState.myRequests.length, Icons.mail_outline),
                        _Count(t.accountStatCart, appState.cart.length,
                            Icons.shopping_cart_outlined),
                      ],
              ),
              const SizedBox(height: 18),
              GoldPanel(
                title: t.accountProfileSection,
                icon: Icons.person_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.bio.isEmpty ? t.accountBioEmpty : user.bio,
                      style: TextStyle(
                          height: 1.5,
                          color: user.bio.isEmpty ? kMuted : kInk,
                          fontStyle: user.bio.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal),
                    ),
                    const SizedBox(height: 14),
                    _Fact(Icons.mail_outline, user.email),
                    _Fact(
                        Icons.translate,
                        user.languages
                            .map((l) => languageLabel(context, l))
                            .join(', ')),
                    if (pro)
                      _Fact(Icons.place_outlined, cityLabel(context, user.city)),
                    if (user.createdAt != null)
                      _Fact(Icons.event_outlined,
                          t.accountMemberSince(fmtDate(user.createdAt!))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GoldPanel(
                title: t.accountActions,
                icon: Icons.settings_outlined,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.edit_outlined, color: kPrimary),
                      title: Text(t.editProfile),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: edit,
                    ),
                    const Divider(height: 1, color: kLine),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: Text(t.logout,
                          style: const TextStyle(color: Colors.red)),
                      onTap: appState.logout,
                    ),
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

/// Fascia dorata con foto, nome e ruoli.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.onEdit});
  final Guide user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final roles = user.roles.isEmpty ? [Role.turista] : user.roles;
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
            padding: const EdgeInsets.all(3),
            decoration:
                const BoxDecoration(color: kSurface, shape: BoxShape.circle),
            child: UserAvatar(user: user, radius: 40),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.greetingHello(user.name),
                    style: const TextStyle(
                        fontFamily: kSerif,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: kInk)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final r in roles)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kNight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(roleLabel(context, r),
                            style: const TextStyle(
                                color: kGold,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    if (user.role.isProfessional)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified, size: 16, color: kInk),
                          const SizedBox(width: 4),
                          Text(t.verifiedSuffix,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    if (user.isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kSurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(t.adminBadge,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: t.editProfile,
            style: IconButton.styleFrom(backgroundColor: kSurface),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: kInk),
          ),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.label, this.value, this.icon);
  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      width: width < 600 ? (width - 64) / 3 : 228,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kPrimary, size: 20),
          const SizedBox(height: 6),
          Text('$value',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: kInk)),
          Text(label,
              maxLines: 2,
              style: const TextStyle(color: kMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: kPrimary),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(color: kInk))),
          ],
        ),
      );
}

import 'package:flutter/material.dart';

import '../l10n/labels.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'auth_screen.dart';
import 'profile_edit_screen.dart';

/// Account: se non loggato mostra l'accesso, altrimenti il riepilogo del
/// profilo con modifica e logout.
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
        return PageBody(
          maxWidth: 480,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.greetingHello(user.name),
                  style: const TextStyle(
                      fontFamily: kSerif,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: kInk)),
              const SizedBox(height: 6),
              Text(
                  user.role.isProfessional
                      ? '${roleLabel(context, user.role)}'
                          '${user.verified ? ' · ${t.verifiedSuffix}' : ' · ${t.unverifiedSuffix}'}'
                      : user.email,
                  style: const TextStyle(color: kMuted)),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ProfileEditScreen())),
                icon: const Icon(Icons.edit_outlined),
                label: Text(t.editProfile),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: appState.logout,
                icon: const Icon(Icons.logout),
                label: Text(t.logout),
              ),
            ],
          ),
        );
      },
    );
  }
}

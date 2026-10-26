/// Profilo restituito da un provider di accesso social.
class SocialProfile {
  const SocialProfile({
    required this.name,
    required this.email,
    required this.provider,
  });
  final String name;
  final String email;
  final String provider; // 'google' | 'facebook'
}

/// Punto di integrazione per Google/Facebook. Per l'accesso reale sostituire
/// [DemoSocialAuth] con un'implementazione basata su Firebase Auth
/// (o google_sign_in / flutter_facebook_auth) e le relative chiavi OAuth.
abstract class SocialAuth {
  /// Restituisce null se l'utente annulla.
  Future<SocialProfile?> signIn(String provider);
}

/// Simulazione senza rete: restituisce sempre lo stesso account di prova.
class DemoSocialAuth implements SocialAuth {
  @override
  Future<SocialProfile?> signIn(String provider) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return switch (provider) {
      'google' => const SocialProfile(
          name: 'Utente Google',
          email: 'utente.google@gmail.com',
          provider: 'google'),
      _ => const SocialProfile(
          name: 'Utente Facebook',
          email: 'utente.facebook@example.com',
          provider: 'facebook'),
    };
  }
}

final SocialAuth socialAuth = DemoSocialAuth();

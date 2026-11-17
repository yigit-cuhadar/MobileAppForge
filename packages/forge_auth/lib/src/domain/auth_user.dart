import 'package:forge_core/forge_core.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    this.email,
    this.displayName,
    this.isAnonymous = false,
    this.signInMethods = const {},
  });

  final String id;
  final String? email;
  final String? displayName;

  /// A guest session: no credential yet, the data lives only on this uid.
  final bool isAnonymous;

  /// How the user can sign in; empty for a guest.
  final Set<SignInMethod> signInMethods;

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    isAnonymous,
    signInMethods,
  ];
}

enum SocialProvider { google, apple }

enum SignInMethod { email, google, apple }

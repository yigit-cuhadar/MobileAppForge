import 'package:forge_core/forge_core.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    this.email,
    this.displayName,
    this.isAnonymous = false,
    this.signInMethods = const {},
    this.emailVerified = false,
  });

  final String id;
  final String? email;
  final String? displayName;

  /// A guest session: no credential yet, the data lives only on this uid.
  final bool isAnonymous;

  /// How the user can sign in; empty for a guest.
  final Set<SignInMethod> signInMethods;

  /// Whether the user has opened the link Firebase mails to [email].
  final bool emailVerified;

  /// An email and password account whose address is not verified yet. A
  /// Google or Apple sign-in counts as verified.
  bool get needsEmailVerification =>
      !emailVerified &&
      signInMethods.length == 1 &&
      signInMethods.contains(SignInMethod.email);

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    isAnonymous,
    signInMethods,
    emailVerified,
  ];
}

enum SocialProvider { google, apple }

enum SignInMethod { email, google, apple }

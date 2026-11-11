import 'package:forge_core/forge_core.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    this.email,
    this.displayName,
    this.isAnonymous = false,
  });

  final String id;
  final String? email;
  final String? displayName;

  /// A guest session: no credential yet, the data lives only on this uid.
  final bool isAnonymous;

  @override
  List<Object?> get props => [id, email, displayName, isAnonymous];
}

enum SocialProvider { google, apple }

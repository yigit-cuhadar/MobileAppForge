import 'package:forge_core/forge_core.dart';

class AuthUser extends Equatable {
  const AuthUser({required this.id, this.email, this.displayName});

  final String id;
  final String? email;
  final String? displayName;

  @override
  List<Object?> get props => [id, email, displayName];
}

enum SocialProvider { google, apple }

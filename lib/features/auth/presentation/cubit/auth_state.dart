import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;
  final bool isEmailVerified;
  final bool profileUpdateSuccess;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isEmailVerified = false,
    this.profileUpdateSuccess = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
    bool? isEmailVerified,
    bool? profileUpdateSuccess,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      profileUpdateSuccess: profileUpdateSuccess ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [status, user, errorMessage, isEmailVerified, profileUpdateSuccess];
}

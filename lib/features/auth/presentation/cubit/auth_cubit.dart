import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authSub;

  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState()) {
    _init();
  }

  /// Listen to Firebase auth state changes.
  /// On first event we resolve the initial/splash state.
  void _init() {
    _authSub = _authRepository.authStateChanges.listen((user) async {
      if (user != null) {
        try {
          if (state.user != null &&
              state.user!.id == user.id &&
              state.status == AuthStatus.authenticated) {
            emit(state.copyWith(
              isEmailVerified: user.emailConfirmedAt != null,
            ));
            return;
          }

          final userData = await _authRepository.syncUserProfile(user);
          emit(state.copyWith(
            status: AuthStatus.authenticated,
            user: userData,
            isEmailVerified: user.emailConfirmedAt != null,
          ));
        } catch (e) {
          if (state.status != AuthStatus.authenticated) {
            emit(state.copyWith(
              status: AuthStatus.unauthenticated,
              errorMessage: 'Failed to sync account data.',
            ));
          }
        }
      } else {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    });
  }

  // ── Check initial auth (called from splash) ──
  Future<void> checkAuthState() async {
    final user = _authRepository.currentUser;
    if (user != null) {
      try {
        final userData = await _authRepository.syncUserProfile(user);
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: userData,
          isEmailVerified: user.emailConfirmedAt != null,
        ));
      } catch (e) {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } else {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  // ── Refresh email verification status ──
  Future<void> refreshEmailVerification() async {
    try {
      final res = await Supabase.instance.client.auth.getUser();
      final user = res.user;
      if (user != null && user.emailConfirmedAt != null) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          isEmailVerified: true,
        ));
      }
    } catch (_) {
      // Ignore errors during silent background checks
    }
  }

  // ── Sign Up ──
  Future<void> signUp({
    required String fullName,
    required String email,
    required String contactNumber,
    required int age,
    required String password,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await _authRepository.signUp(
        fullName: fullName,
        email: email,
        contactNumber: contactNumber,
        age: age,
        password: password,
      );
      // Supabase sends verification email automatically if enabled
      // await _authRepository.sendEmailVerification();
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isEmailVerified: false,
      ));
    } on AuthException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e.message),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // ── Sign In with Email ──
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );
      final firebaseUser = _authRepository.currentUser;
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isEmailVerified: firebaseUser?.emailConfirmedAt != null,
      ));
    } on AuthException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e.message),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // ── Sign In with Phone ──
  Future<void> signInWithPhone({
    required String contactNumber,
    required String password,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await _authRepository.signInWithPhone(
        contactNumber: contactNumber,
        password: password,
      );
      final firebaseUser = _authRepository.currentUser;
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isEmailVerified: firebaseUser?.emailConfirmedAt != null,
      ));
    } on AuthException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e.message),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // ── Sign In with Google ──
  Future<void> signInWithGoogle() async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _authRepository.signInWithGoogle();
    } on AuthException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e.message),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // ── Forgot Password ──
  Future<void> sendPasswordReset(String email) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _authRepository.sendPasswordResetEmail(email);
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // ── Update Profile ──
  Future<void> updateProfile({
    String? fullName,
    String? contactNumber,
    int? age,
    String? photoUrl,
    dynamic imageFile,
  }) async {
    if (state.user == null) return;
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      String? updatedPhotoUrl = photoUrl;
      if (imageFile != null) {
        updatedPhotoUrl = await _authRepository.uploadProfileImage(
          state.user!.id,
          imageFile,
        );
      }

      final updated = await _authRepository.updateProfile(
        id: state.user!.id,
        fullName: fullName,
        contactNumber: contactNumber,
        age: age,
        photoUrl: updatedPhotoUrl,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: updated,
        profileUpdateSuccess: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // ── Change Password ──
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        profileUpdateSuccess: true,
      ));
    } on AuthException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e.message),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // ── Resend Email Verification ──
  Future<void> resendEmailVerification() async {
    try {
      await _authRepository.sendEmailVerification();
    } catch (_) {}
  }

  // ── Sign Out ──
  Future<void> signOut() async {
    await _authRepository.signOut();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  // ── Clear Error ──
  void clearError() {
    emit(state.copyWith(
      status: state.user != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated,
      profileUpdateSuccess: false,
    ));
  }

  String _mapFirebaseError(String msg) {
    if (msg.contains('already registered') || msg.contains('User already registered')) {
      return 'This email is already registered.';
    }
    if (msg.contains('invalid email') || msg.contains('invalid_email')) {
      return 'Please enter a valid email address.';
    }
    if (msg.contains('weak') || msg.contains('Password should be')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (msg.contains('not found') || msg.contains('Invalid login credentials')) {
      return 'Incorrect credentials. Please try again.';
    }
    if (msg.contains('Email not confirmed')) {
      return 'Please verify your email address before signing in.';
    }
    return 'Authentication failed: $msg';
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}

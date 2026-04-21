import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_entity.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository({
    SupabaseClient? supabase,
  }) : _supabase = supabase ?? Supabase.instance.client;

  Stream<User?> get authStateChanges =>
      _supabase.auth.onAuthStateChange.map((event) => event.session?.user);

  User? get currentUser => _supabase.auth.currentUser;

  Future<UserEntity> signUp({
    required String fullName,
    required String email,
    required String contactNumber,
    required int age,
    required String password,
  }) async {
    final res = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'contact_number': contactNumber,
        'age': age,
      },
    );

    final user = res.user;
    if (user == null) {
      throw Exception('Sign up failed.');
    }

    final now = DateTime.now();
    final userEntity = UserEntity(
      id: user.id,
      fullName: fullName,
      email: email,
      contactNumber: contactNumber,
      age: age,
      createdAt: now,
      updatedAt: now,
    );

    await _upsertUserProfile(userEntity);
    return userEntity;
  }

  Future<void> sendEmailVerification() async {
    final email = currentUser?.email;
    if (email != null) {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    }
  }

  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final res = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = res.user;
    if (user == null) {
      throw Exception('Sign in failed.');
    }

    return _getOrCreateUserData(user);
  }

  Future<UserEntity> signInWithPhone({
    required String contactNumber,
    required String password,
  }) async {
    final data = await _supabase
        .from('users')
        .select('email')
        .eq('contact_number', contactNumber)
        .limit(1);

    if ((data as List).isEmpty) {
      throw const AuthException(
        'No user found with this contact number.',
        statusCode: 'user-not-found',
      );
    }

    final email = data.first['email'] as String;
    return signInWithEmail(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    final didLaunch = await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.flutter://callback',
    );

    if (!didLaunch) {
      throw Exception('Google sign in could not be started.');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<UserEntity> updateProfile({
    required String id,
    String? fullName,
    String? contactNumber,
    int? age,
    String? photoUrl,
  }) async {
    final existing = await _supabase
        .from('users')
        .select()
        .eq('id', id)
        .maybeSingle();

    final updates = <String, dynamic>{
      'id': id,
      'email': existing?['email'] ?? currentUser?.email ?? '',
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (existing != null && existing['created_at'] != null) {
      updates['created_at'] = existing['created_at'];
    }
    if (fullName != null) updates['full_name'] = fullName;
    if (contactNumber != null) updates['contact_number'] = contactNumber;
    if (age != null) updates['age'] = age;
    if (photoUrl != null) updates['photo_url'] = photoUrl;

    if (fullName != null) {
      await _supabase.auth.updateUser(
        UserAttributes(data: {'full_name': fullName}),
      );
    }

    try {
      await _supabase.from('users').upsert(updates, onConflict: 'id');
    } on PostgrestException catch (e) {
      throw Exception(_mapDataError(e, table: 'users'));
    }

    return _getUserData(id);
  }

  Future<String> uploadProfileImage(String id, File imageFile) async {
    final path = 'profile_images/$id.jpg';
    await _supabase.storage.from('profiles').upload(
          path,
          imageFile,
          fileOptions: const FileOptions(upsert: true),
        );
    return _supabase.storage.from('profiles').getPublicUrl(path);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<UserEntity> getUserData(String id) => _getUserData(id);

  Future<UserEntity> syncUserProfile(User authUser) => _getOrCreateUserData(authUser);

  Future<UserEntity> _getUserData(String id) async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (data == null) {
        throw Exception('User data not found');
      }
      return UserEntity.fromMap(data);
    } on PostgrestException catch (e) {
      throw Exception(_mapDataError(e, table: 'users'));
    }
  }

  Future<UserEntity> _getOrCreateUserData(User authUser) async {
    final existing = await _supabase
        .from('users')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();

    if (existing != null) {
      return UserEntity.fromMap(existing);
    }

    final metadata = authUser.userMetadata ?? <String, dynamic>{};
    final now = DateTime.now();
    final inferredUser = UserEntity(
      id: authUser.id,
      fullName: (metadata['full_name'] ??
              metadata['name'] ??
              authUser.email?.split('@').first ??
              'User')
          .toString(),
      email: authUser.email ?? '',
      contactNumber: (metadata['contact_number'] ?? '').toString(),
      age: _parseAge(metadata['age']),
      photoUrl:
          metadata['avatar_url']?.toString() ?? metadata['picture']?.toString(),
      createdAt: now,
      updatedAt: now,
    );

    await _upsertUserProfile(inferredUser);
    return inferredUser;
  }

  Future<void> _upsertUserProfile(UserEntity user) async {
    try {
      await _supabase.from('users').upsert(user.toMap(), onConflict: 'id');
    } on PostgrestException catch (e) {
      throw Exception(_mapDataError(e, table: 'users'));
    }
  }

  int _parseAge(dynamic rawAge) {
    if (rawAge is int) return rawAge;
    return int.tryParse(rawAge?.toString() ?? '') ?? 0;
  }

  String _mapDataError(PostgrestException error, {required String table}) {
    final message = error.message.toLowerCase();
    if (message.contains('relation') && message.contains('does not exist')) {
      return 'Supabase table "$table" is missing. Please create the required database tables first.';
    }
    if (message.contains('row-level security') ||
        message.contains('permission denied')) {
      return 'Supabase blocked access to "$table". Please add select/insert/update policies for authenticated users.';
    }
    return error.message;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}

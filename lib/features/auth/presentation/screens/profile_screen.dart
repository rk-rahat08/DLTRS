import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../app/theme/theme_cubit.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  bool _isEditing = false;
  File? _imageFile;
  DateTime? _selectedDate;
  int _age = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = context.read<AuthCubit>().state.user;
    if (user != null) {
      _nameController.text = user.fullName;
      _phoneController.text = user.contactNumber;
      _age = user.age;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _isEditing = true;
      });
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now.subtract(Duration(days: 365 * _age)),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (d != null) {
      int age = now.year - d.year;
      if (now.month < d.month ||
          (now.month == d.month && now.day < d.day)) {
        age--;
      }
      setState(() {
        _selectedDate = d;
        _age = age;
        _isEditing = true;
      });
    }
  }

  Future<void> _saveProfile() async {
    await context.read<AuthCubit>().updateProfile(
          fullName: _nameController.text.trim(),
          contactNumber: _phoneController.text.trim(),
          age: _age,
          imageFile: _imageFile,
        );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<AuthCubit>().clearError();
        }
        if (state.profileUpdateSuccess) {
          setState(() {
            _isEditing = false;
            _imageFile = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (_isEditing)
              TextButton(
                onPressed: _saveProfile,
                child: const Text('Save',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              )
            else
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => setState(() => _isEditing = true),
              ),
          ],
        ),
        body: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final user = state.user;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // ── Avatar ──
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(55),
                            child: _imageFile != null
                                ? Image.file(_imageFile!,
                                    fit: BoxFit.cover,
                                    width: 110,
                                    height: 110)
                                : (user?.photoUrl != null &&
                                        user!.photoUrl!.isNotEmpty)
                                    ? CachedNetworkImage(
                                        imageUrl: user.photoUrl!,
                                        fit: BoxFit.cover,
                                        width: 110,
                                        height: 110,
                                        placeholder: (_, __) => Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          user?.fullName.isNotEmpty == true
                                              ? user!.fullName[0]
                                                  .toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 42,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showImagePicker,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: isDark
                                        ? AppColors.darkBackground
                                        : Colors.white,
                                    width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(0.2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.camera_alt,
                                  size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.fullName ?? '',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 32),

                  // ── Profile Fields ──
                  GlassCard(
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          enabled: _isEditing,
                          onChanged: (_) {
                            if (!_isEditing) setState(() => _isEditing = true);
                          },
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          enabled: _isEditing,
                          onChanged: (_) {
                            if (!_isEditing) setState(() => _isEditing = true);
                          },
                          decoration: const InputDecoration(
                            labelText: 'Contact Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Date of Birth / Age picker
                        GestureDetector(
                          onTap: _isEditing ? _pickDateOfBirth : null,
                          child: AbsorbPointer(
                            child: TextFormField(
                              enabled: _isEditing,
                              decoration: InputDecoration(
                                labelText: 'Age',
                                prefixIcon:
                                    const Icon(Icons.cake_outlined),
                                suffixIcon: _isEditing
                                    ? const Icon(
                                        Icons.calendar_month_rounded,
                                        color: AppColors.primary)
                                    : null,
                              ),
                              controller: TextEditingController(
                                text: _selectedDate != null
                                    ? '${DateFormat('MMM d, yyyy').format(_selectedDate!)} (Age: $_age)'
                                    : 'Age: $_age',
                              ),
                            ),
                          ),
                        ),
                        if (_isEditing && state.status == AuthStatus.loading)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Theme Toggle ──
                  GlassCard(
                    margin: EdgeInsets.zero,
                    child: BlocBuilder<ThemeCubit, bool>(
                      builder: (context, isDarkMode) {
                        return Row(
                          children: [
                            Icon(
                              isDarkMode
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Dark Mode',
                                style:
                                    Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            Switch(
                              value: isDarkMode,
                              onChanged: (v) =>
                                  context.read<ThemeCubit>().setDarkMode(v),
                              activeTrackColor: AppColors.primary,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Change Password ──
                  GlassCard(
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change Password',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _currentPassController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Current Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _newPassController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'New Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GradientButton(
                          text: 'Update Password',
                          gradient: AppColors.secondaryGradient,
                          onPressed: () {
                            if (_currentPassController.text.isNotEmpty &&
                                _newPassController.text.length >= 6) {
                              context.read<AuthCubit>().changePassword(
                                    currentPassword:
                                        _currentPassController.text,
                                    newPassword: _newPassController.text,
                                  );
                              _currentPassController.clear();
                              _newPassController.clear();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'New password must be at least 6 characters'),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Logout ──
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Sign Out'),
                            content: const Text(
                                'Are you sure you want to sign out?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  context.read<AuthCubit>().signOut();
                                },
                                child: const Text('Sign Out',
                                    style:
                                        TextStyle(color: AppColors.error)),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout_rounded,
                          color: AppColors.error),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(color: AppColors.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _phoneNumber = '';
  DateTime? _selectedDate;
  int _calculatedAge = 0;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _calculateAge(DateTime bday) {
    final now = DateTime.now();
    int age = now.year - bday.year;
    if (now.month < bday.month ||
        (now.month == bday.month && now.day < bday.day)) {
      age--;
    }
    setState(() {
      _selectedDate = bday;
      _calculatedAge = age;
    });
  }

  Future<void> _pickDate() async {
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (d != null) {
      _calculateAge(d);
    }
  }

  void _signUp() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _calculatedAge < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid date of birth (age >= 5).'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<AuthCubit>().signUp(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          contactNumber: _phoneNumber,
          age: _calculatedAge,
          password: _passwordController.text,
        );
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
        if (state.status == AuthStatus.authenticated) {
          // Show success message - GoRouter redirect handles navigation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created! Please verify your email.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'Create Account',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start organizing your daily life',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                  ),
                  const SizedBox(height: 32),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Full Name
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(v)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Phone with country code selector
                        IntlPhoneField(
                          decoration: const InputDecoration(
                            labelText: 'Contact Number',
                            counterText: '',
                          ),
                          initialCountryCode: 'BD',
                          onChanged: (phone) {
                            _phoneNumber = phone.completeNumber;
                          },
                          validator: (v) {
                            if (v == null || v.completeNumber.isEmpty) {
                              return 'Please enter your contact number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Date of Birth picker
                        GestureDetector(
                          onTap: _pickDate,
                          child: AbsorbPointer(
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: _selectedDate == null
                                    ? 'Date of Birth'
                                    : 'Date of Birth (Age: $_calculatedAge)',
                                prefixIcon: const Icon(Icons.cake_outlined),
                                suffixIcon: const Icon(
                                    Icons.calendar_month_rounded,
                                    color: AppColors.primary),
                              ),
                              controller: TextEditingController(
                                text: _selectedDate == null
                                    ? ''
                                    : DateFormat('MMMM d, yyyy')
                                        .format(_selectedDate!),
                              ),
                              validator: (_) {
                                if (_selectedDate == null) {
                                  return 'Please pick your date of birth';
                                }
                                if (_calculatedAge < 5) {
                                  return 'You must be at least 5 years old';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (v.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Confirm Password
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (v) {
                            if (v != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      return GradientButton(
                        text: 'Create Account',
                        isLoading: state.status == AuthStatus.loading,
                        onPressed: _signUp,
                        icon: Icons.person_add_alt_1_rounded,
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Google Sign Up ──
                  Row(
                    children: [
                      Expanded(
                          child: Divider(
                              color: isDark
                                  ? AppColors.darkDivider
                                  : AppColors.lightDivider)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Or sign up with',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Expanded(
                          child: Divider(
                              color: isDark
                                  ? AppColors.darkDivider
                                  : AppColors.lightDivider)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Material(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 1,
                    child: InkWell(
                      onTap: () =>
                          context.read<AuthCubit>().signInWithGoogle(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkDivider
                                : AppColors.lightDivider,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.g_mobiledata_rounded,
                                size: 32, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

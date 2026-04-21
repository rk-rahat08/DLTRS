import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'dart:async';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  Timer? _timer;
  bool _canResend = true;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Periodically check if email is verified
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (mounted) {
        await context.read<AuthCubit>().refreshEmailVerification();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _resend() {
    if (!_canResend) return;
    context.read<AuthCubit>().resendEmailVerification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification email resent!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Start cooldown
    setState(() {
      _canResend = false;
      _resendCooldown = 60;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 0) {
        timer.cancel();
        if (mounted) setState(() => _canResend = true);
      } else {
        if (mounted) setState(() => _resendCooldown--);
      }
    });
  }

  void _signOut() {
    context.read<AuthCubit>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userEmail = context.read<AuthCubit>().state.user?.email ?? '';

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        // When email is verified, the router redirect will handle navigation
        if (state.isEmailVerified && state.status == AuthStatus.authenticated) {
          // Router will pick this up and redirect to /dashboard
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with gradient background
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Verify Your Email',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We\'ve sent a verification link to',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Click the link in the email to verify your account. This page will update automatically.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Waiting indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary.withOpacity(0.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Waiting for verification...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Resend button
                  GradientButton(
                    text: _canResend
                        ? 'Resend Verification Email'
                        : 'Resend in ${_resendCooldown}s',
                    onPressed: _canResend ? _resend : null,
                    icon: Icons.refresh_rounded,
                  ),
                  const SizedBox(height: 16),

                  // Sign out
                  TextButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.error, size: 18),
                    label: const Text(
                      'Use Different Account',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

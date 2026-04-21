import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/verification_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/main_shell.dart';
import '../../features/tasks/presentation/screens/tasks_screen.dart';
import '../../features/tasks/presentation/screens/create_task_screen.dart';
import '../../features/habits/presentation/screens/habits_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/notes/presentation/screens/notes_screen.dart';
import '../../features/notes/presentation/screens/note_editor_screen.dart';
import '../../features/focus_mode/presentation/screens/focus_mode_screen.dart';
import '../../features/productivity/presentation/screens/productivity_screen.dart';
import '../../core/services/service_locator.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(getIt<AuthCubit>().stream),
    redirect: (context, state) {
      final authState = getIt<AuthCubit>().state;
      final authStatus = authState.status;
      final isAuth = authStatus == AuthStatus.authenticated;
      final isEmailVerified = authState.isEmailVerified;

      final currentPath = state.matchedLocation;
      final isSplash = currentPath == '/splash';
      final isAuthRoute = currentPath == '/login' ||
          currentPath == '/signup' ||
          currentPath == '/forgot-password';
      final isVerifyRoute = currentPath == '/verify';

      // While checking auth state, stay on splash
      if (authStatus == AuthStatus.initial ||
          authStatus == AuthStatus.loading) {
        if (!isSplash) return '/splash';
        return null;
      }

      // Not authenticated → go to login (unless already on auth route)
      if (!isAuth) {
        if (isAuthRoute || isSplash) {
          // If on splash and not auth, redirect to login
          if (isSplash) return '/login';
          return null;
        }
        return '/login';
      }

      // Authenticated but email not verified → verification screen
      if (isAuth && !isEmailVerified) {
        if (isVerifyRoute) return null;
        return '/verify';
      }

      // Authenticated and verified → dashboard (if on auth/splash/verify routes)
      if (isAuth && isEmailVerified) {
        if (isAuthRoute || isSplash || isVerifyRoute) {
          return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/verify',
        name: 'verify',
        builder: (_, __) => const VerificationScreen(),
      ),
      // ── Auth Routes ──
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

      // ── Main Shell (bottom navigation) ──
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/tasks',
            name: 'tasks',
            builder: (_, __) => const TasksScreen(),
          ),
          GoRoute(
            path: '/habits',
            name: 'habits',
            builder: (_, __) => const HabitsScreen(),
          ),
          GoRoute(
            path: '/calendar',
            name: 'calendar',
            builder: (_, __) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/notes',
            name: 'notes',
            builder: (_, __) => const NotesScreen(),
          ),
        ],
      ),

      // ── Full-Screen Routes ──
      GoRoute(
        path: '/create-task',
        name: 'create-task',
        builder: (_, __) => const CreateTaskScreen(),
      ),
      GoRoute(
        path: '/note-editor',
        name: 'note-editor',
        builder: (_, state) => NoteEditorScreen(
          noteId: state.uri.queryParameters['id'],
        ),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/focus-mode',
        name: 'focus-mode',
        builder: (_, __) => const FocusModeScreen(),
      ),
      GoRoute(
        path: '/productivity',
        name: 'productivity',
        builder: (_, __) => const ProductivityScreen(),
      ),
    ],
  );
}

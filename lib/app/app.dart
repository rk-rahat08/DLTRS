import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme/app_theme.dart';
import 'theme/theme_cubit.dart';
import 'routes/app_router.dart';
import '../core/services/service_locator.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/tasks/presentation/cubit/tasks_cubit.dart';

class DltrsApp extends StatelessWidget {
  final bool isDarkMode;

  const DltrsApp({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthCubit>()),
        BlocProvider(create: (_) => getIt<TasksCubit>()),
        BlocProvider(create: (_) => ThemeCubit(initialTheme: isDarkMode)),
      ],
      child: BlocBuilder<ThemeCubit, bool>(
        builder: (context, isDark) {
          final router = AppRouter.router;
          return MaterialApp.router(
            title: 'DLTRS',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            routerConfig: router,
          );
        },
      ),
    );
  }
}

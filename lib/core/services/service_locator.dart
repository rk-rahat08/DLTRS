import 'package:get_it/get_it.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/tasks/data/repositories/task_repository.dart';
import '../../features/tasks/presentation/cubit/tasks_cubit.dart';
import '../../features/habits/data/repositories/habit_repository.dart';
import '../../features/notes/data/repositories/note_repository.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // ── Repositories ──
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository());
  getIt.registerLazySingleton<TaskRepository>(() => TaskRepository());
  getIt.registerLazySingleton<HabitRepository>(() => HabitRepository());
  getIt.registerLazySingleton<NoteRepository>(() => NoteRepository());

  // ── Cubits ──
  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(authRepository: getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<TasksCubit>(
    () => TasksCubit(taskRepository: getIt<TaskRepository>()),
  );
}

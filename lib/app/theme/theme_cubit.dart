import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<bool> {
  static const _key = 'isDarkMode';

  ThemeCubit({required bool initialTheme}) : super(initialTheme);

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !state;
    await prefs.setBool(_key, newValue);
    emit(newValue);
  }

  Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, isDark);
    emit(isDark);
  }
}

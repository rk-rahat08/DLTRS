import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary Palette ──
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFF8B7CF6);
  static const Color primaryDark = Color(0xFF5A4BD1);

  // ── Secondary Palette ──
  static const Color secondary = Color(0xFF00CEC9);
  static const Color secondaryLight = Color(0xFF55EFC4);
  static const Color secondaryDark = Color(0xFF00B5B0);

  // ── Accent ──
  static const Color accent = Color(0xFFFD79A8);
  static const Color accentLight = Color(0xFFFAB1C8);
  static const Color accentDark = Color(0xFFE84393);

  // ── Semantic ──
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDAA5D);
  static const Color error = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF74B9FF);

  // ── Priority Colours ──
  static const Color priorityLow = Color(0xFF55EFC4);
  static const Color priorityMedium = Color(0xFFFDAA5D);
  static const Color priorityHigh = Color(0xFFFF6B6B);

  // ── Light Theme ──
  static const Color lightBackground = Color(0xFFF8F9FE);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF2D3436);
  static const Color lightTextSecondary = Color(0xFF636E72);
  static const Color lightDivider = Color(0xFFE8E9F3);
  static const Color lightShimmer = Color(0xFFEEEFF5);

  // ── Dark Theme ──
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCard = Color(0xFF1C2333);
  static const Color darkText = Color(0xFFF0F6FC);
  static const Color darkTextSecondary = Color(0xFF8B949E);
  static const Color darkDivider = Color(0xFF30363D);
  static const Color darkShimmer = Color(0xFF21262D);

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFFF472B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1C2333), Color(0xFF161B22)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return priorityHigh;
      case 'medium':
        return priorityMedium;
      case 'low':
        return priorityLow;
      default:
        return priorityMedium;
    }
  }
}

import 'package:flutter/material.dart';

/// 纸张 / 墨色 / 强调色，全局统一使用
class AppColors {
  AppColors._();

  static const Color paper = Color(0xFFF6F2E9);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardWarm = Color(0xFFFCFAF4);
  static const Color ink = Color(0xFF17150F);
  static const Color inkSoft = Color(0xFF5C574C);
  static const Color muted = Color(0xFF918A7B);
  static const Color line = Color(0xFFE6DFD0);
  static const Color accent = Color(0xFF1F5E4C);
  static const Color gold = Color(0xFFB8873B);
}

class AppTheme {
  AppTheme._();

  /// 大号数字 / 标题：优先衬线体，营造「成长手账」的编辑感
  static TextStyle display({
    double size = 30,
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: 'serif',
      fontFamilyFallback: const ['Noto Serif', 'Source Han Serif SC', 'Songti SC'],
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.08,
      letterSpacing: -0.4,
    );
  }

  /// 小号字距标签，如「今日寄语」「ANALYSIS」
  static const TextStyle overline = TextStyle(
    fontSize: 10.5,
    letterSpacing: 2.2,
    fontWeight: FontWeight.w600,
    color: AppColors.muted,
  );

  static ThemeData light() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    final text = base.textTheme;

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        onPrimary: Colors.white,
        secondary: AppColors.gold,
        onSecondary: Colors.white,
        surface: AppColors.card,
        onSurface: AppColors.ink,
        outline: AppColors.line,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.ink,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
          letterSpacing: 0.6,
        ),
      ),
      textTheme: text.copyWith(
        bodyLarge: text.bodyLarge?.copyWith(color: AppColors.ink, height: 1.5),
        bodyMedium: text.bodyMedium?.copyWith(color: AppColors.inkSoft, height: 1.55),
        bodySmall: text.bodySmall?.copyWith(color: AppColors.muted, height: 1.4),
        titleMedium: text.titleMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 13),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
        ),
      ),
    );
  }
}

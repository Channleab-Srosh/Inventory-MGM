import 'package:flutter/material.dart';

/// App color palette and theme configuration
class AppColors {
  // Design system core colors
  static const primary = Color(0xFF1A3351);
  static const primaryLight = Color(0xFF2E4D71);
  static const primaryDark = Color(0xFF0F1E30);

  static const background = Color(0xFFF5F7FA);
  static const card = Color(0xFFFFFFFF);
  static const text = Color(0xFF1F2937);
  static const secondaryText = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);

  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);

  // Status colors (aligned with design tokens)
  static const inStock = success;
  static const lowStock = warning;
  static const outOfStock = danger;

  // Neutral aliases for compatibility
  static const grey50 = Color(0xFFF9FAFB);
  static const grey100 = background;
  static const grey200 = border;
  static const grey500 = secondaryText;
  static const grey800 = text;
  static const grey900 = Color(0xFF111827);

  // Chart
  static const chartIn = success;
  static const chartOut = danger;
}

class AppTheme {
  static const _cardRadius = 16.0;
  static const _screenPadding = 16.0;

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark  => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryLight,
      surface: isDark ? AppColors.grey800 : AppColors.card,
      error: AppColors.danger,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.grey800 : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
          side: BorderSide(
            color: isDark ? Colors.transparent : AppColors.border,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: isDark ? AppColors.grey900 : AppColors.card,
        foregroundColor: isDark ? Colors.white : AppColors.text,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Bottom nav / NavigationBar
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: isDark ? AppColors.grey900 : AppColors.card,
        elevation: 2,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return IconThemeData(
            color: isDark ? AppColors.grey500 : AppColors.secondaryText,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.grey500 : AppColors.secondaryText,
          );
        }),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.grey800 : AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(
          color: isDark ? AppColors.grey500 : AppColors.secondaryText,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.danger, width: 2),
        ),
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 50),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),

      // Scaffold background
      scaffoldBackgroundColor: isDark ? AppColors.grey900 : AppColors.background,

      // Divider
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.grey800 : AppColors.border,
        space: 1,
        thickness: 1,
      ),

      // Text
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.text,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.text,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.text,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : AppColors.text,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: isDark ? AppColors.grey200 : AppColors.text,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: isDark ? AppColors.grey200 : AppColors.secondaryText,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.grey500 : AppColors.secondaryText,
        ),
      ),

      extensions: const [
        AppSpacing(screenPadding: _screenPadding, cardRadius: _cardRadius),
      ],
    );
  }
}

/// Theme extension to access spacing constants
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({required this.screenPadding, required this.cardRadius});
  final double screenPadding;
  final double cardRadius;

  @override
  AppSpacing copyWith({double? screenPadding, double? cardRadius}) => AppSpacing(
        screenPadding: screenPadding ?? this.screenPadding,
        cardRadius: cardRadius ?? this.cardRadius,
      );

  @override
  AppSpacing lerp(AppSpacing? other, double t) => this;
}

import 'package:flutter/material.dart';

/// App color palette and theme configuration matching the new modern design system
class AppColors {
  // 1. Color Palette
  // App Background: Soft light gray (#F5F6F8)
  static const background = Color(0xFFF5F6F8);

  // Surface / Cards: Pure white (#FFFFFF)
  static const card = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFECEEF2);
  static const subtleBorder = Color(0xFFECEEF2);

  // Primary Accent: Soft periwinkle/lavender purple
  // #A594F9 for featured cards / accents, #EBE8FC for active state backgrounds
  static const primary = Color(0xFFA594F9);
  static const primaryDark = Color(0xFF735BF2);
  static const primaryLight = Color(0xFFB8AAFA);
  static const primaryActive = Color(0xFFEBE8FC);
  static const activeBackground = Color(0xFFEBE8FC);

  // Typography Colors: Deep charcoal (#1A1A1A) & Muted gray (#8E929B)
  static const text = Color(0xFF1A1A1A);
  static const heading = Color(0xFF1A1A1A);
  static const secondaryText = Color(0xFF8E929B);
  static const muted = Color(0xFF8E929B);

  // Semantic Status Colors (Pill Badges & Icons)
  // Success / In Stock: Mint green text (#2E9B68) on pale green background (#E8F7F0)
  static const inStockText = Color(0xFF2E9B68);
  static const inStockBg = Color(0xFFE8F7F0);
  static const inStock = Color(0xFF2E9B68);
  static const success = Color(0xFF2E9B68);
  static const successBg = Color(0xFFE8F7F0);

  // Warning / Low Stock: Amber/orange text (#D99B26) on pale yellow background (#FDF6E7)
  static const lowStockText = Color(0xFFD99B26);
  static const lowStockBg = Color(0xFFFDF6E7);
  static const lowStock = Color(0xFFD99B26);
  static const warning = Color(0xFFD99B26);
  static const warningBg = Color(0xFFFDF6E7);

  // Danger / Out of Stock: Coral red text (#E04F5F) on pale pink background (#FDECEE)
  static const outOfStockText = Color(0xFFE04F5F);
  static const outOfStockBg = Color(0xFFFDECEE);
  static const outOfStock = Color(0xFFE04F5F);
  static const danger = Color(0xFFE04F5F);
  static const dangerBg = Color(0xFFFDECEE);

  // Chart accents
  static const chartIn = Color(0xFF2E9B68);
  static const chartOut = Color(0xFFE04F5F);
  static const chartAreaLavender = Color(0xFFA594F9);

  // Neutral aliases for compatibility
  static const grey50 = Color(0xFFFAFBFD);
  static const grey100 = background;
  static const grey200 = border;
  static const grey500 = secondaryText;
  static const grey800 = text;
  static const grey900 = Color(0xFF141416);

  // Soft diffused drop shadow for cards
  static const softShadow = BoxShadow(
    color: Color(0x071A1A1A),
    blurRadius: 14,
    offset: Offset(0, 4),
  );

  static const cardShadow = [
    BoxShadow(
      color: Color(0x061A1A1A),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const lavenderShadow = [
    BoxShadow(
      color: Color(0x28A594F9),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
}

class AppTheme {
  static const cardRadius = 16.0;
  static const bentoRadius = 24.0;
  static const pillRadius = 999.0;
  static const screenPadding = 18.0;

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark  => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryActive,
      onSecondary: AppColors.primaryDark,
      surface: AppColors.card,
      onSurface: AppColors.text,
      error: AppColors.danger,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,

      // Scaffold background: Soft light gray (#F5F6F8)
      scaffoldBackgroundColor: AppColors.background,

      // Card: Pure white (#FFFFFF) with subtle border and 16px radius
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      ),

      // Minimalist AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        iconTheme: IconThemeData(
          color: AppColors.text,
          size: 22,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),

      // Bottom Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: AppColors.card,
        elevation: 0,
        indicatorColor: AppColors.primaryActive,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryDark, size: 22);
          }
          return const IconThemeData(
            color: AppColors.secondaryText,
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryText,
          );
        }),
      ),

      // Text Fields: Pure white fill with subtle borders and smooth corners (never black)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: AppColors.secondaryText,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: AppColors.secondaryText,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primaryDark,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: AppColors.secondaryText,
        suffixIconColor: AppColors.secondaryText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppColors.primaryDark, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),

      // Buttons: 999px (full pill) shape
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pillRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: AppColors.border, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pillRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pillRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: StadiumBorder(),
      ),

      // Chip Theme: 999px pill tabs
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pillRadius)),
        side: const BorderSide(color: AppColors.border),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        space: 1,
        thickness: 1,
      ),

      // Typography & Hierarchy
      // Clean geometric sans-serif typography with tight tracking
      textTheme: const TextTheme(
        // Headings: Bold, 22px–26px, tight tracking
        headlineLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          color: AppColors.text,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: AppColors.text,
        ),
        // Metric Values & Section Headers
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: AppColors.text,
        ),
        // Body / Item Titles: Semi-bold, 15px–16px
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: AppColors.text,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          color: AppColors.text,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.text,
        ),
        // Captions / Metadata: Regular, 12px–13px, muted gray
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.secondaryText,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.secondaryText,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.secondaryText,
        ),
      ),

      extensions: const [
        AppSpacing(screenPadding: screenPadding, cardRadius: cardRadius),
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

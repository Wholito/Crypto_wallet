import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppTheme {
  static const yellow = Color(0xFFF5C400);
  static const yellowSoft = Color(0xFFFFE066);
  static const black = Color(0xFF0A0A0A);
  static const ink = Color(0xFF111111);
  static const white = Color(0xFFFFFFFF);
  static const paper = Color(0xFFF7F7F4);
  static const darkSurface = Color(0xFF161616);
  static const darkCard = Color(0xFF1E1E1E);
  static const lightCard = Color(0xFFFFFFFF);

  static final ThemeData lightTheme = _build(Brightness.light);
  static final ThemeData darkTheme = _build(Brightness.dark);

  static ThemeData light() => lightTheme;

  static ThemeData dark() => darkTheme;

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? black : paper;
    final card = isDark ? darkCard : lightCard;
    final onSurface = isDark ? white : ink;
    final muted = isDark ? const Color(0xFFB8B8B8) : const Color(0xFF5C5C5C);
    final outline = isDark ? const Color(0xFF333333) : const Color(0xFFE2E2DC);
    final scheme = ColorScheme(
      brightness: brightness,
      primary: yellow,
      onPrimary: black,
      primaryContainer: isDark ? const Color(0xFF3A3000) : const Color(0xFFFFF3BF),
      onPrimaryContainer: isDark ? yellowSoft : const Color(0xFF3A3000),
      secondary: yellowSoft,
      onSecondary: black,
      secondaryContainer: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFF8D6),
      onSecondaryContainer: onSurface,
      tertiary: yellow,
      onTertiary: black,
      error: const Color(0xFFE53935),
      onError: white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: isDark ? darkSurface : const Color(0xFFEEEEEA),
      onSurfaceVariant: muted,
      outline: outline,
      outlineVariant: outline,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? paper : ink,
      onInverseSurface: isDark ? ink : white,
      inversePrimary: const Color(0xFFB8860B),
    );
    final radius = BorderRadius.circular(18);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      canvasColor: surface,
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: outline.withValues(alpha: isDark ? 0.9 : 1)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: scheme.primary,
      ),
      dividerTheme: DividerThemeData(
        color: outline.withValues(alpha: 0.8),
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        circularTrackColor: outline,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return black;
          return isDark ? const Color(0xFF888888) : const Color(0xFF777777);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return yellow;
          return outline;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return yellow;
          return muted;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: yellow, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: yellow,
          foregroundColor: black,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: radius),
          side: BorderSide(color: isDark ? yellow : outline, width: 1.4),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? yellowSoft : const Color(0xFF8A6A00),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: yellow,
        foregroundColor: black,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? darkCard : ink,
        contentTextStyle: TextStyle(color: isDark ? white : white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      iconTheme: IconThemeData(color: onSurface),
      primaryIconTheme: const IconThemeData(color: black),
    );
  }
}

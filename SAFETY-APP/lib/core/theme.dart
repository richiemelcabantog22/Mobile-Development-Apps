import 'package:flutter/material.dart';

ThemeData buildDynamicLightTheme({required Color seed, required double textScale}) {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF7F7FC),
  );

  return base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: base.colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    // Use TabBarThemeData (M3 friendly)
    tabBarTheme: TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12 * textScale),
      unselectedLabelStyle: TextStyle(fontSize: 12 * textScale),
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: Colors.white, width: 2),
      ),
    ),
    // IMPORTANT: Do not apply fontSizeFactor to TextTheme here to avoid
    // TextStyle.apply assertion on styles with null fontSize. We scale via MediaQuery.
    textTheme: base.textTheme,

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(base.colorScheme.primary),
        foregroundColor: MaterialStateProperty.all(base.colorScheme.onPrimary),
        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
        textStyle: MaterialStateProperty.all(TextStyle(fontSize: 18 * textScale, fontWeight: FontWeight.bold)),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(base.colorScheme.primary),
        textStyle: MaterialStateProperty.all(TextStyle(fontSize: 14 * textScale, fontWeight: FontWeight.w600)),
      ),
    ),

    cardColor: Colors.white,
    dividerColor: Colors.black12,
  );
}

ThemeData buildDynamicDarkTheme({required Color seed, required double textScale}) {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
    useMaterial3: true,
    brightness: Brightness.dark,
  );

  return base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: base.colorScheme.primary,
      foregroundColor: base.colorScheme.onPrimary,
      elevation: 0,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12 * textScale),
      unselectedLabelStyle: TextStyle(fontSize: 12 * textScale),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: base.colorScheme.secondary, width: 2),
      ),
    ),
    // IMPORTANT: Avoid TextTheme.apply with non-1.0 factor to prevent assertions.
    textTheme: base.textTheme,

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(base.colorScheme.secondary),
        foregroundColor: MaterialStateProperty.all(base.colorScheme.onSecondary),
        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
        textStyle: MaterialStateProperty.all(TextStyle(fontSize: 18 * textScale, fontWeight: FontWeight.bold)),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(base.colorScheme.secondary),
        textStyle: MaterialStateProperty.all(TextStyle(fontSize: 14 * textScale, fontWeight: FontWeight.w600)),
      ),
    ),
  );
}
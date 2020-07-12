import 'package:flutter/material.dart';

const kDbdRed = const Color(0xFF9D0B0D);
const kDbdMutedRed = const Color(0xFF660D0E);

const kDbdGrey = const Color(0xFF1C1C1C);

TextTheme _buildDBDTextTheme(TextTheme base) {
  return base
      .copyWith(
          headline6: base.headline6
              .copyWith(fontWeight: FontWeight.w300, fontSize: 20.0),
          headline5: base.headline5.copyWith(fontWeight: FontWeight.w800),
          caption: base.caption
              .copyWith(fontWeight: FontWeight.w200, fontSize: 14.0),
          bodyText1: base.bodyText1
              .copyWith(fontWeight: FontWeight.w300, fontSize: 16.0))
      .apply(
        fontFamily: "Open Sans",
      );
}

ThemeData _buildTheme() {
  final ThemeData base = ThemeData.dark();
  return base.copyWith(
      accentColor: kDbdRed,
      textTheme: _buildDBDTextTheme(base.textTheme),
      primaryTextTheme: _buildDBDTextTheme(base.primaryTextTheme),
      accentTextTheme: _buildDBDTextTheme(base.accentTextTheme));
}

ThemeData mainTheme = _buildTheme();

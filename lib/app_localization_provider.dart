import 'package:flutter/widgets.dart';

class TranslationMapper {
  static List<Locale> _supportedLocales = [];

  /// Set the supported locales
  static void setSupportedLocales(List<Locale> locales) {
    _supportedLocales = locales;
  }

  /// Get the supported locales
  static List<Locale> get supportedLocales => _supportedLocales;
}

import 'package:flutter/widgets.dart';

/// Process-wide registry of the locales an app ships translation files for.
///
/// Call [setSupportedLocales] once at startup, before `runApp`, then reuse
/// [supportedLocales] for `MaterialApp.supportedLocales` so the app and the
/// `CustomLocalizationDelegate` agree on the same list:
///
/// ```dart
/// void main() {
///   TranslationMapper.setSupportedLocales(const [Locale('en'), Locale('fr')]);
///   runApp(const MyApp());
/// }
///
/// MaterialApp(
///   localizationsDelegates: [CustomLocalization.delegate],
///   supportedLocales: TranslationMapper.supportedLocales,
/// );
/// ```
///
/// The delegate only reports a locale as supported when it is in this list,
/// so a locale that is missing here is never loaded even if a matching
/// `.arb` file is bundled.
///
/// See also:
///
///  * [CustomLocalizationDelegate.isSupported], which consults this list.
class TranslationMapper {
  static List<Locale> _supportedLocales = [];

  /// Replaces the list of supported locales with [locales].
  ///
  /// Each entry should correspond to a bundled `.arb` file, e.g.
  /// `Locale('de')` for `lib/l10n/app_de.arb` or `Locale('de', 'CH')` for
  /// `lib/l10n/app_de_CH.arb` (with `app_de.arb` as a fallback).
  ///
  /// This is normally called once in `main` before `runApp`. Changing the list
  /// after the app has started does not reload already-built
  /// `Localizations` widgets.
  static void setSupportedLocales(List<Locale> locales) {
    _supportedLocales = locales;
  }

  /// The locales registered with [setSupportedLocales].
  ///
  /// Empty until [setSupportedLocales] is called. Pass this to
  /// `MaterialApp.supportedLocales` (or `WidgetsApp.supportedLocales`).
  static List<Locale> get supportedLocales => _supportedLocales;
}

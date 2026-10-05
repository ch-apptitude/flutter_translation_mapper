import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_translation_mapper/app_localization_provider.dart';

/// The translations of a single locale, as loaded by [CustomLocalizationDelegate].
///
/// Instances are created by the delegate and made available to the widget tree
/// through Flutter's `Localizations` widget. Retrieve the one for the current
/// locale with [of], or simply call `context.translate(...)` from
/// `LocalizationExtension`, which does the lookup for you.
///
/// ```dart
/// final loc = CustomLocalization.of(context)!;
/// loc.get('greeting', params: {'name': 'Ada'});
/// ```
class CustomLocalization {
  final Map<String, String> _entries;

  /// The delegate to add to `MaterialApp.localizationsDelegates`.
  ///
  /// A single shared instance, so settings such as
  /// [CustomLocalizationDelegate.filePrefix] can be changed in `main` before
  /// `runApp` and apply everywhere:
  ///
  /// ```dart
  /// CustomLocalization.delegate.filePrefix = 'translations_';
  /// ```
  static final CustomLocalizationDelegate delegate =
      CustomLocalizationDelegate();

  /// Called when [get] finds no entry for a key, before the `"??:key"`
  /// fallback is returned. Null by default. Apps use it to report missing
  /// keys (analytics, crash reporting, debug assertions):
  ///
  /// ```dart
  /// CustomLocalization.onMissingKey = (key) {
  ///   myLogger.warning('No translation for "$key"');
  ///   assert(false, 'No translation for l10n key "$key"');
  /// };
  /// ```
  ///
  /// The callback is invoked exactly once per miss. It is not guarded: an
  /// exception thrown from it propagates out of [get] (and therefore out of
  /// `context.translate`), so an app can deliberately fail fast in debug.
  static void Function(String key)? onMissingKey;

  /// Creates a localization backed by the given key-to-translation map.
  ///
  /// Apps normally do not call this; [delegate] builds instances from `.arb`
  /// files. It is useful in tests to inject fixed translations.
  CustomLocalization(this._entries);

  /// The [CustomLocalization] for the locale of the closest `Localizations`
  /// ancestor of [context], or null if none is found.
  ///
  /// Returns null when [delegate] is not registered in
  /// `localizationsDelegates`, or when [context] is above the `MaterialApp`.
  /// Prefer `context.translate(...)` from `LocalizationExtension`, which
  /// throws a descriptive [FlutterError] in that case instead of returning
  /// null.
  static CustomLocalization? of(BuildContext context) {
    return Localizations.of<CustomLocalization>(context, CustomLocalization);
  }

  /// Returns the translation for [key], substituting [params] into it.
  ///
  /// For every entry in [params], each occurrence of `{entryKey}` in the
  /// translated string is replaced by `entryValue.toString()`. Placeholders
  /// with no matching param are left untouched, and params with no matching
  /// placeholder are ignored. Only this simple substitution is supported:
  /// plurals, selects and date or number formatting are not interpreted.
  ///
  /// ```dart
  /// // app_en.arb: "greeting": "Hello, {name}!"
  /// loc.get('greeting', params: {'name': 'Ada'}); // "Hello, Ada!"
  /// ```
  ///
  /// When [key] has no translation, [onMissingKey] is called (if set) and the
  /// string `"??:key"` is returned so the miss is visible in the UI rather
  /// than crashing the app.
  String get(String key, {Map<String, dynamic>? params}) {
    String? translation = _entries[key];

    if (translation == null) {
      onMissingKey?.call(key);
      return "??:$key";
    }

    // If no parameters provided, return translation as-is
    if (params == null || params.isEmpty) {
      return translation;
    }

    // Replace placeholders with actual values
    String result = translation;
    params.forEach((paramKey, paramValue) {
      result = result.replaceAll('{$paramKey}', paramValue.toString());
    });

    return result;
  }
}

/// Ordered list of `.arb` file-name stems to try for [locale], most specific
/// first (e.g. `de_CH` before `de`). Exposed for testing — the ordering is
/// the whole point of the language+country fallback fix.
@visibleForTesting
List<String> localeFileCandidates(Locale locale) => <String>[
  if (locale.countryCode != null && locale.countryCode!.isNotEmpty)
    '${locale.languageCode}_${locale.countryCode}',
  locale.languageCode,
];

/// Loads a [CustomLocalization] from the `.arb` file matching a locale.
///
/// Use the shared instance [CustomLocalization.delegate] rather than creating
/// your own, so that [filePrefix] changes are picked up everywhere.
///
/// Files are read from the asset bundle at `lib/l10n/<filePrefix><locale>.arb`
/// and must therefore be declared under `flutter: assets:` in `pubspec.yaml`.
/// For a locale with a country code the country-specific file is tried first
/// and the language-only file second; see [load] for the full rules.
///
/// A locale counts as supported only if it is present in
/// [TranslationMapper.supportedLocales].
class CustomLocalizationDelegate
    extends LocalizationsDelegate<CustomLocalization> {
  /// File-name prefix of the translation files, `'app_'` by default.
  ///
  /// With the default, `Locale('en')` loads `lib/l10n/app_en.arb`. Set it
  /// before `runApp` to match another naming convention:
  ///
  /// ```dart
  /// CustomLocalization.delegate.filePrefix = 'translations_';
  /// // now loads lib/l10n/translations_en.arb
  /// ```
  String filePrefix = 'app_';

  @override
  bool isSupported(Locale locale) =>
      TranslationMapper.supportedLocales.contains(locale);

  @override
  bool shouldReload(CustomLocalizationDelegate old) => false;

  /// Loads the translations for [locale] from the asset bundle.
  ///
  /// Candidate files are tried in the order given by [localeFileCandidates]:
  /// `lib/l10n/<filePrefix>de_CH.arb` and then `lib/l10n/<filePrefix>de.arb`
  /// for `Locale('de', 'CH')`, or only the latter for `Locale('de')`. The
  /// first file that exists is used; files are never merged, so a
  /// country-specific file has to contain every key.
  ///
  /// Entries whose key starts with `@` (ARB metadata) and entries whose value
  /// is not a string are skipped. This method never throws:
  ///
  ///  * if the chosen file is malformed JSON, the error is logged and an
  ///    empty localization is returned, so every lookup renders as `??:key`
  ///    instead of silently falling back to another file;
  ///  * if no candidate file exists, the attempted paths are logged and an
  ///    empty localization is returned.
  ///
  /// Diagnostics are written with `dart:developer` `log` under the
  /// `CustomLocalization` logger name.
  @override
  Future<CustomLocalization> load(Locale locale) async {
    // Prefer a full language+country file (e.g. "de_CH") when the locale has
    // a country code, falling back to the language-only file (e.g. "de").
    // Trying the language-only file unconditionally — as this used to do —
    // meant a country-specific locale (like de_CH) silently lost every
    // translation whenever no language-only file was bundled, even though a
    // perfectly good language+country file existed right next to it.
    final candidates = localeFileCandidates(locale);

    for (final candidate in candidates) {
      final path = 'lib/l10n/$filePrefix$candidate.arb';

      // A missing candidate is expected (most apps only bundle a
      // language-only file), so it is logged as a plain message, not an error.
      final String json;
      try {
        json = await rootBundle.loadString(path);
      } catch (_) {
        developer.log(
          'No localization file at $path, trying next candidate',
          name: 'CustomLocalization',
        );
        continue;
      }

      // From here on the file exists, so we commit to it. A malformed file
      // must NOT fall through to the next candidate: that would silently serve
      // the wrong translations and hide the broken file. Returning an empty
      // localization makes every lookup render as "??:key", which is visible
      // in QA without crashing the app.
      final Map<String, dynamic> decoded;
      try {
        decoded = jsonDecode(json) as Map<String, dynamic>;
      } catch (e, stackTrace) {
        developer.log(
          'Failed to parse $path; returning empty localization',
          name: 'CustomLocalization',
          level: _severe,
          error: e,
          stackTrace: stackTrace,
        );
        return CustomLocalization({});
      }

      // Filter out metadata entries (keys starting with @) and ensure string values
      final entries = <String, String>{};
      var skippedEntries = 0;

      decoded.forEach((key, value) {
        if (key.startsWith('@')) {
          // Skip metadata entries
          return;
        }

        if (value is String) {
          entries[key] = value;
        } else {
          skippedEntries++;
          developer.log(
            'Skipped non-string value for key "$key" (type: ${value.runtimeType})',
            name: 'CustomLocalization',
          );
        }
      });

      developer.log(
        'Loaded ${entries.length} translations from $path${skippedEntries > 0 ? " ($skippedEntries entries skipped)" : ""}',
        name: 'CustomLocalization',
      );

      return CustomLocalization(entries);
    }

    // No candidate exists at all — this is the genuinely unexpected case, so
    // it is the one logged as an error. Return an empty localization rather
    // than crashing; callers see "??:key" for every lookup.
    developer.log(
      'No localization file found for locale $locale '
      '(tried: ${candidates.map((c) => "lib/l10n/$filePrefix$c.arb").join(", ")}); '
      'returning empty localization as fallback',
      name: 'CustomLocalization',
      level: _severe,
    );
    return CustomLocalization({});
  }
}

/// `package:logging` SEVERE level, so these entries stand out from the plain
/// informational messages in DevTools and `flutter logs`.
const int _severe = 1000;

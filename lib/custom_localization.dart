import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_translation_mapper/app_localization_provider.dart';

class CustomLocalization {
  final Map<String, String> _entries;
  static final CustomLocalizationDelegate delegate =
      CustomLocalizationDelegate();

  CustomLocalization(this._entries);

  static CustomLocalization? of(BuildContext context) {
    return Localizations.of<CustomLocalization>(context, CustomLocalization);
  }

  String get(String key, {Map<String, dynamic>? params}) {
    String? translation = _entries[key];

    if (translation == null) {
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

class CustomLocalizationDelegate
    extends LocalizationsDelegate<CustomLocalization> {
  String filePrefix = 'app_';

  @override
  bool isSupported(Locale locale) =>
      TranslationMapper.supportedLocales.contains(locale);

  @override
  bool shouldReload(CustomLocalizationDelegate old) => false;

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
      try {
        developer.log(
          'Loading localization for locale: $candidate',
          name: 'CustomLocalization',
        );

        final json = await rootBundle.loadString("lib/l10n/$filePrefix$candidate.arb");

        Map<String, dynamic> decoded;
        try {
          decoded = jsonDecode(json);
        } catch (e) {
          developer.log(
            'Failed to parse JSON for locale $candidate',
            name: 'CustomLocalization',
            error: e,
          );
          rethrow;
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
          'Loaded ${entries.length} translations for $candidate${skippedEntries > 0 ? " ($skippedEntries entries skipped)" : ""}',
          name: 'CustomLocalization',
        );

        return CustomLocalization(entries);
      } catch (e, stackTrace) {
        developer.log(
          'Failed to load custom localization for candidate $candidate',
          name: 'CustomLocalization',
          error: e,
          stackTrace: stackTrace,
        );
        // Try the next candidate (if any) before giving up.
      }
    }

    // All candidates failed — return empty localization as fallback to
    // prevent an app crash. Callers see "??:key" for every lookup, which is
    // loud enough to notice in QA but won't take the app down.
    developer.log(
      'No localization file found for locale $locale (tried: ${candidates.join(", ")}); returning empty localization as fallback',
      name: 'CustomLocalization',
    );
    return CustomLocalization({});
  }
}

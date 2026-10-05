## Unreleased

* Added an `example/` app showing the delegate setup, the `.arb` assets and
  `context.translate` with and without parameters.
* Documented the whole public API (`TranslationMapper`, `CustomLocalization`,
  `CustomLocalizationDelegate`, `LocalizationExtension`) and the library
  entry point.
* Added pub.dev `topics` to `pubspec.yaml`.

## 0.2.0

* **Missing-key hook**: new static `CustomLocalization.onMissingKey` callback,
  called once with the key whenever `get` (and therefore `context.translate`)
  finds no translation, before the `??:key` fallback is returned. Null by
  default, so existing apps are unaffected. The callback is not guarded: an
  exception it throws propagates to the caller, which lets apps `assert` or
  throw in debug builds. Reachable through the main
  `flutter_translation_mapper.dart` export.
* **Regional locale resolution**: a locale with a country code (e.g. `de_CH`)
  now loads `app_de_CH.arb` first and falls back to `app_de.arb` only when the
  regional file is missing. Previously the language-only file was always
  used, so a locale with only a regional file bundled got no translations.
* **Behaviour change**: if both `app_de.arb` and `app_de_CH.arb` are bundled,
  the regional file now takes precedence for `de_CH`. Files are not merged,
  so a regional file must contain every key. Apps that keep a partial regional
  ARB (common with `gen_l10n`) should complete it or drop the regional locale
  from `setSupportedLocales`.
* A malformed `.arb` file is no longer masked by a fallback: the parse error is
  logged and an empty localization is returned, so lookups render as `??:key`.
* A missing candidate file is logged as a plain message; only parse failures
  and "no file found at all" are logged at error level.
* Added tests covering candidate ordering, fallback, malformed files, metadata
  filtering and custom file prefixes.

## 0.1.0

* Initial release
* Key-based translations with dynamic variable replacements
* Custom localization delegate for Flutter apps
* BuildContext extension for easy translation access
* Support for .arb translation files
* Fallback translation support to prevent crashes

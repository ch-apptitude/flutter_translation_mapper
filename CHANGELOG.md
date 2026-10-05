## 0.2.0

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

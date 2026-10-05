# flutter_translation_mapper example

A minimal app showing the three steps needed to use the package:

1. `TranslationMapper.setSupportedLocales(...)` in `main()`.
2. `CustomLocalization.delegate` in `MaterialApp.localizationsDelegates`.
3. `context.translate('key', params: {...})` in widgets.

Translation files live in `lib/l10n/app_en.arb` and `lib/l10n/app_fr.arb` and
are declared as assets in `pubspec.yaml`. The button at the bottom switches
between the two locales.

## Running

The platform folders are not committed. Generate them for the platforms you
want, then run as usual:

```sh
flutter create . --platforms=ios,android
flutter run
```

```sh
flutter test
```

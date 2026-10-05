/// Key-based localization for Flutter with simple `{variable}` substitution,
/// loaded from `.arb` files in the asset bundle.
///
/// Three steps to use it:
///
/// 1. Register the locales you ship a translation file for with
///    [TranslationMapper.setSupportedLocales].
/// 2. Add [CustomLocalization.delegate] to `MaterialApp.localizationsDelegates`
///    and pass [TranslationMapper.supportedLocales] as `supportedLocales`.
/// 3. Read translations in widgets with `context.translate('key')` from
///    [LocalizationExtension].
///
/// ```dart
/// void main() {
///   TranslationMapper.setSupportedLocales(const [Locale('en'), Locale('fr')]);
///   runApp(const MyApp());
/// }
///
/// MaterialApp(
///   localizationsDelegates: [
///     CustomLocalization.delegate,
///     GlobalMaterialLocalizations.delegate,
///     GlobalWidgetsLocalizations.delegate,
///   ],
///   supportedLocales: TranslationMapper.supportedLocales,
///   home: const HomePage(),
/// );
///
/// Text(context.translate('greeting', params: {'name': 'Ada'}));
/// ```
///
/// Translation files are plain `.arb` JSON files (`lib/l10n/app_en.arb`,
/// `lib/l10n/app_fr.arb`, ...) declared as assets in `pubspec.yaml`. Keys
/// starting with `@` are treated as metadata and ignored. See
/// [CustomLocalizationDelegate] for the file lookup rules and
/// [CustomLocalization.onMissingKey] for reporting missing keys.
library;

export 'custom_localization.dart';
export 'localization_extension.dart';
export 'app_localization_provider.dart';

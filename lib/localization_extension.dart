import 'package:flutter/material.dart';
import 'custom_localization.dart';

/// Adds [translate] to [BuildContext] for one-call access to the
/// [CustomLocalization] of the nearest enclosing `Localizations` widget.
///
/// ```dart
/// Text(context.translate('welcome'));
/// Text(context.translate('greeting', params: {'name': 'Ada'}));
/// ```
extension LocalizationExtension on BuildContext {
  /// Returns the translation for [key] in the current locale.
  ///
  /// Shorthand for `CustomLocalization.of(context)!.get(key, params: params)`.
  ///
  /// Each entry in [params] replaces the `{name}` placeholder of the same name
  /// in the translated string; values are converted with `toString()`. See
  /// [CustomLocalization.get] for the exact substitution and fallback rules.
  ///
  /// If [key] has no translation, `"??:key"` is returned so the miss is
  /// visible in the UI instead of crashing, and
  /// [CustomLocalization.onMissingKey] is invoked if set.
  ///
  /// Throws a [FlutterError] when no [CustomLocalization] is available above
  /// this context. That happens when [CustomLocalization.delegate] is not in
  /// `MaterialApp.localizationsDelegates`, or when this is called from a
  /// context above `MaterialApp` (for example the `builder` of `runApp`).
  String translate(String key, {Map<String, dynamic>? params}) {
    final customLoc = CustomLocalization.of(this);
    if (customLoc == null) {
      throw FlutterError(
        'CustomLocalization not found in context. '
        'Make sure CustomLocalization.delegate is added to localizationsDelegates.',
      );
    }
    return customLoc.get(key, params: params);
  }
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_translation_mapper/custom_localization.dart';

void main() {
  group('localeFileCandidates', () {
    test('tries the language+country file before the language-only file', () {
      expect(
        localeFileCandidates(const Locale.fromSubtags(
          languageCode: 'de',
          countryCode: 'CH',
        )),
        ['de_CH', 'de'],
      );
    });

    test('only tries the language file when there is no country code', () {
      expect(
        localeFileCandidates(const Locale.fromSubtags(languageCode: 'en')),
        ['en'],
      );
      expect(
        localeFileCandidates(const Locale.fromSubtags(languageCode: 'fr')),
        ['fr'],
      );
    });

  });

  group('CustomLocalization.get', () {
    test('returns the translation when the key exists', () {
      final localization = CustomLocalization({'greeting': 'Hello'});
      expect(localization.get('greeting'), 'Hello');
    });

    test('returns a visibly-broken "??:key" marker for an unknown key', () {
      final localization = CustomLocalization({});
      expect(localization.get('missingKey'), '??:missingKey');
    });

    test('substitutes params into the translation', () {
      final localization = CustomLocalization({'welcome': 'Hi {name}!'});
      expect(
        localization.get('welcome', params: {'name': 'Léa'}),
        'Hi Léa!',
      );
    });
  });
}

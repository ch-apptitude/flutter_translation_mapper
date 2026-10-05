import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_translation_mapper/custom_localization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('CustomLocalizationDelegate.load', () {
    const deCH = Locale.fromSubtags(languageCode: 'de', countryCode: 'CH');

    /// Fake asset bundle contents, keyed by asset path.
    late Map<String, String> assets;

    /// Every asset path the delegate asked the platform for, in order.
    late List<String> requested;

    setUp(() {
      assets = {};
      requested = [];
      // rootBundle caches loaded strings, so clear it between tests.
      rootBundle.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (ByteData? message) async {
        final key = utf8.decode(
          message!.buffer.asUint8List(
            message.offsetInBytes,
            message.lengthInBytes,
          ),
        );
        requested.add(key);
        final content = assets[key];
        if (content == null) {
          // null tells rootBundle the asset does not exist.
          return null;
        }
        return ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });

    test('uses the language+country file when it exists', () async {
      assets['lib/l10n/app_de_CH.arb'] = '{"greeting": "Grüezi"}';
      assets['lib/l10n/app_de.arb'] = '{"greeting": "Hallo"}';

      final localization = await CustomLocalizationDelegate().load(deCH);

      expect(localization.get('greeting'), 'Grüezi');
      expect(requested, ['lib/l10n/app_de_CH.arb']);
    });

    test('falls back to the language-only file when the regional one is missing',
        () async {
      assets['lib/l10n/app_de.arb'] = '{"greeting": "Hallo"}';

      final localization = await CustomLocalizationDelegate().load(deCH);

      expect(localization.get('greeting'), 'Hallo');
      expect(requested, ['lib/l10n/app_de_CH.arb', 'lib/l10n/app_de.arb']);
    });

    test('returns an empty localization when no candidate exists', () async {
      final localization = await CustomLocalizationDelegate().load(deCH);

      expect(localization.get('greeting'), '??:greeting');
      expect(requested, ['lib/l10n/app_de_CH.arb', 'lib/l10n/app_de.arb']);
    });

    test('does not fall back when the regional file is malformed', () async {
      assets['lib/l10n/app_de_CH.arb'] = '{"greeting": ';
      assets['lib/l10n/app_de.arb'] = '{"greeting": "Hallo"}';

      final localization = await CustomLocalizationDelegate().load(deCH);

      // A broken file must stay visible, not be masked by the base file.
      expect(localization.get('greeting'), '??:greeting');
      expect(requested, ['lib/l10n/app_de_CH.arb']);
    });

    test('skips @metadata and non-string values', () async {
      assets['lib/l10n/app_en.arb'] =
          '{"@@locale": "en", "greeting": "Hello", "@greeting": {}, "count": 3}';

      final localization = await CustomLocalizationDelegate()
          .load(const Locale.fromSubtags(languageCode: 'en'));

      expect(localization.get('greeting'), 'Hello');
      expect(localization.get('@@locale'), '??:@@locale');
      expect(localization.get('count'), '??:count');
    });

    test('honours a custom file prefix', () async {
      assets['lib/l10n/translations_de_CH.arb'] = '{"greeting": "Grüezi"}';

      final localization = await (CustomLocalizationDelegate()
            ..filePrefix = 'translations_')
          .load(deCH);

      expect(localization.get('greeting'), 'Grüezi');
      expect(requested, ['lib/l10n/translations_de_CH.arb']);
    });
  });
}

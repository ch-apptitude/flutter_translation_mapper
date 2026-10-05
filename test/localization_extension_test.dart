import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_translation_mapper/flutter_translation_mapper.dart';

/// Serves a fixed [CustomLocalization] so tests can exercise
/// `context.translate` without touching the asset bundle.
class _FixedLocalizationDelegate
    extends LocalizationsDelegate<CustomLocalization> {
  const _FixedLocalizationDelegate(this.localization);

  final CustomLocalization localization;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CustomLocalization> load(Locale locale) =>
      SynchronousFuture(localization);

  @override
  bool shouldReload(_FixedLocalizationDelegate old) => false;
}

/// Pumps a tree with [localization] installed and returns a [BuildContext]
/// below it, so `context.translate` can be called from the test body (where
/// a thrown exception reaches `expect`, rather than being swallowed by the
/// framework's build error handling).
Future<BuildContext> pumpWithLocalization(
  WidgetTester tester,
  CustomLocalization localization,
) async {
  late BuildContext captured;
  await tester.pumpWidget(
    Localizations(
      locale: const Locale('en'),
      delegates: [
        _FixedLocalizationDelegate(localization),
        DefaultWidgetsLocalizations.delegate,
      ],
      child: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  group('context.translate', () {
    late List<String> reported;

    setUp(() {
      reported = [];
      CustomLocalization.onMissingKey = reported.add;
    });

    tearDown(() {
      CustomLocalization.onMissingKey = null;
    });

    testWidgets('returns the translation and does not report a hit', (
      tester,
    ) async {
      final context = await pumpWithLocalization(
        tester,
        CustomLocalization({'greeting': 'Hello {name}'}),
      );

      expect(
        context.translate('greeting', params: {'name': 'Léa'}),
        'Hello Léa',
      );
      expect(reported, isEmpty);
    });

    testWidgets('reports a missing key and returns the "??:key" fallback', (
      tester,
    ) async {
      final context = await pumpWithLocalization(
        tester,
        CustomLocalization({}),
      );

      expect(context.translate('missingKey'), '??:missingKey');
      expect(reported, ['missingKey']);
    });

    testWidgets('a throwing hook propagates out of translate', (tester) async {
      CustomLocalization.onMissingKey = (key) {
        throw StateError('No translation for "$key"');
      };
      final context = await pumpWithLocalization(
        tester,
        CustomLocalization({}),
      );

      expect(
        () => context.translate('missingKey'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'No translation for "missingKey"',
          ),
        ),
      );
    });

    testWidgets(
      'throws a FlutterError when no CustomLocalization is installed',
      (tester) async {
        late BuildContext captured;
        await tester.pumpWidget(
          Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        );

        expect(() => captured.translate('greeting'), throwsFlutterError);
        expect(reported, isEmpty);
      },
    );
  });
}

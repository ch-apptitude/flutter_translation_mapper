import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_translation_mapper/flutter_translation_mapper.dart';
import 'package:flutter_translation_mapper_example/main.dart';

void main() {
  setUp(() {
    // main() does this before runApp; the test pumps ExampleApp directly.
    TranslationMapper.setSupportedLocales(const [Locale('en'), Locale('fr')]);
  });

  testWidgets('translates strings and switches locale', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    // The delegate loads the .arb file asynchronously.
    await tester.pumpAndSettle();

    expect(find.text('Welcome to the example app!'), findsOneWidget);
    expect(find.text('Hello, Ada!'), findsOneWidget);
    expect(find.text('You have 3 items in your cart.'), findsOneWidget);
    expect(find.text('??:missingKey'), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Bonjour, Ada !'), findsOneWidget);
  });
}

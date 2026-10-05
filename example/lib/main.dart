import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_translation_mapper/flutter_translation_mapper.dart';

void main() {
  // 1. Declare the locales you ship a translation file for. The delegate only
  //    reports these as supported, and `supportedLocales` below reuses them.
  TranslationMapper.setSupportedLocales(const [Locale('en'), Locale('fr')]);

  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  Locale _locale = const Locale('en');

  void _toggleLocale() {
    setState(() {
      _locale = _locale.languageCode == 'en'
          ? const Locale('fr')
          : const Locale('en');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,
      // 2. Add the package delegate next to Flutter's own delegates.
      localizationsDelegates: [
        CustomLocalization.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: TranslationMapper.supportedLocales,
      home: HomePage(onToggleLocale: _toggleLocale),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onToggleLocale});

  final VoidCallback onToggleLocale;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 3. Read translations anywhere below MaterialApp with context.translate.
      appBar: AppBar(title: Text(context.translate('appTitle'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            // Plain key lookup.
            Text(context.translate('welcome')),
            // `{name}` in the .arb value is replaced by the matching param.
            Text(context.translate('greeting', params: {'name': 'Ada'})),
            // Any value works: it is converted with toString().
            Text(context.translate('itemCount', params: {'count': 3})),
            // A missing key never crashes; it renders as "??:key".
            Text(context.translate('missingKey')),
            FilledButton(
              onPressed: onToggleLocale,
              child: Text(context.translate('switchLocale')),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:benzina/app/app.dart';
import 'package:benzina/app/router.dart';
import 'package:benzina/data/location_service.dart';
import 'package:benzina/data/mock_fuel_repository.dart';
import 'package:benzina/push/push_gateway.dart';
import 'package:benzina/push/push_providers.dart';
import 'package:benzina/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

Widget buildApp({
  ThemeMode themeMode = ThemeMode.light,
  PushGateway push = const DisabledPushGateway(),
}) {
  return ProviderScope(
    retry: noRetry,
    overrides: [
      pushGatewayProvider.overrideWithValue(push),
      fuelRepositoryProvider.overrideWithValue(
        MockFuelRepository(latency: Duration.zero),
      ),
      locationServiceProvider.overrideWithValue(const FixedLocationService()),
      settingsProvider.overrideWith(
        () => SettingsNotifier(AppSettings(themeMode: themeMode)),
      ),
    ],
    child: BenzinaApp(
      router: buildRouter(splashDuration: const Duration(milliseconds: 10)),
    ),
  );
}

Future<void> passSplash(WidgetTester tester) async {
  // Schermo di un telefono (390×844 punti).
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    PackageInfo.setMockInitialValues(
      appName: 'Benzina',
      packageName: 'it.markitiello.benzina',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('dalla splash si arriva alla home con il più economico', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    expect(find.text('Il pieno al prezzo giusto'), findsOneWidget);

    await passSplash(tester);
    expect(find.text('Vicino a te'), findsOneWidget);
    expect(find.text('IL PIÙ ECONOMICO'), findsOneWidget);
    expect(find.text('Q8 Easy'), findsOneWidget);
  });

  testWidgets('dettaglio distributore con valutazione Google', (tester) async {
    await tester.pumpWidget(buildApp());
    await passSplash(tester);

    await tester.tap(find.text('Q8 Easy'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Valutazione Google'), 300);
    expect(find.text('Valutazione Google'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Vedi recensioni su Google Maps'),
      300,
    );
    expect(find.text('Valutazioni fornite da Google'), findsOneWidget);
  });

  testWidgets('risultati: icone di bar e bancomat', (tester) async {
    await tester.pumpWidget(buildApp());
    await passSplash(tester);

    // I dati di prova hanno il bancomat ovunque e il bar a distributori alterni.
    expect(find.byIcon(Icons.atm_rounded), findsWidgets);
    expect(find.byIcon(Icons.local_cafe_rounded), findsWidgets);
    expect(find.byTooltip('Bancomat'), findsWidgets);
    // Gli altri servizi solo nel dettaglio.
    expect(find.byIcon(Icons.wifi_rounded), findsNothing);
  });

  testWidgets('dettaglio: servizi, orari e contatti', (tester) async {
    await tester.pumpWidget(buildApp());
    await passSplash(tester);

    await tester.tap(find.text('Q8 Easy'));
    await tester.pumpAndSettle();
    expect(find.text('Bancomat'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Orari'), 300);
    expect(find.text('Lunedì'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Contatti'), 300);
    expect(find.byIcon(Icons.phone_rounded), findsOneWidget);
  });

  testWidgets('preferiti: il prezzo dice a quale carburante si riferisce', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await passSplash(tester);

    await tester.tap(find.text('Q8 Easy'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Aggiungi ai preferiti'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Preferiti'));
    await tester.pumpAndSettle();
    expect(find.text('€/l · Benzina self'), findsOneWidget);
  });

  testWidgets('notifiche: segna tutte come lette', (tester) async {
    await tester.pumpWidget(buildApp());
    await passSplash(tester);

    await tester.tap(find.byTooltip('Notifiche, 2 non lette'));
    await tester.pumpAndSettle();
    expect(find.text('Notifiche'), findsOneWidget);

    await tester.tap(find.text('Segna tutte come lette'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Notifiche'), findsOneWidget);
  });

  testWidgets('impostazioni mostrano la versione', (tester) async {
    await tester.pumpWidget(buildApp(themeMode: ThemeMode.dark));
    await passSplash(tester);

    await tester.tap(find.byTooltip('Impostazioni'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('1.0.0 (sviluppo)'), 200);
    expect(find.text('1.0.0 (sviluppo)'), findsOneWidget);
  });

  testWidgets('scheda Andamento', (tester) async {
    await tester.pumpWidget(buildApp());
    await passSplash(tester);

    await tester.tap(find.text('Andamento'));
    await tester.pumpAndSettle();
    expect(find.text('Andamento prezzi'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Un anno fa'), 300);
    expect(find.text('Un anno fa'), findsOneWidget);
  });
}

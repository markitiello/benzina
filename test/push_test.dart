import 'dart:async';

import 'package:benzina/data/models.dart';
import 'package:benzina/push/push_gateway.dart';
import 'package:benzina/push/push_message.dart';
import 'package:benzina/push/push_topics.dart';
import 'package:benzina/push/topic_sync.dart';
import 'package:benzina/state/providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_test.dart' show buildApp, passSplash;

/// Firebase finto: registra iscrizioni e permette di simulare notifiche.
class FakePushGateway implements PushGateway {
  FakePushGateway({this.permission = true});

  final bool permission;
  final subscribed = <String>{};
  final calls = <String>[];
  final receivedController = StreamController<PushMessage>.broadcast();
  final openedController = StreamController<PushMessage>.broadcast();

  @override
  bool get isAvailable => true;

  @override
  Future<bool> requestPermission() async {
    calls.add('permission');
    return permission;
  }

  @override
  Future<void> subscribe(String topic) async {
    calls.add('+$topic');
    subscribed.add(topic);
  }

  @override
  Future<void> unsubscribe(String topic) async {
    calls.add('-$topic');
    subscribed.remove(topic);
  }

  @override
  Stream<PushMessage> get received => receivedController.stream;

  @override
  Stream<PushMessage> get opened => openedController.stream;

  @override
  Future<PushMessage?> launchMessage() async => null;
}

PushMessage trendMessage({String direction = 'down'}) => PushMessage(
  id: 'm1',
  title: direction == 'down'
      ? 'Benzina self in calo'
      : 'Benzina self in aumento',
  body: 'Media nazionale 1,819 €/l: −1,2% in 3 giorni.',
  data: {
    'type': 'trend',
    'fuel': 'benzina',
    'mode': 'self',
    'direction': direction,
    'day': '2026-09-23',
  },
  receivedAt: DateTime(2026, 9, 23, 9, 30),
);

void main() {
  group('topic', () {
    test('coincidono con quelli del backend (src/Trend/Topics.php)', () {
      expect(allTrendTopics, [
        'trend_benzina_self',
        'trend_benzina_servito',
        'trend_diesel_self',
        'trend_diesel_servito',
        'trend_gpl',
        'trend_metano',
      ]);
    });

    test('solo il carburante scelto, se gli avvisi sono attivi', () {
      expect(desiredTopics(const AppSettings()), {'trend_benzina_self'});
      expect(
        desiredTopics(
          const AppSettings(fuel: FuelType.diesel, mode: ServiceMode.servito),
        ),
        {'trend_diesel_servito'},
      );
      expect(
        desiredTopics(
          const AppSettings(fuel: FuelType.gpl, mode: ServiceMode.servito),
        ),
        {'trend_gpl'},
      );
      expect(desiredTopics(const AppSettings(trendAlerts: false)), isEmpty);
    });

    test(
      'sincronizzazione: iscrive al topic voluto e disiscrive dagli altri',
      () async {
        final push = FakePushGateway()..subscribed.add('trend_gpl');
        expect(await syncTrendTopics(push, {'trend_diesel_self'}), isTrue);
        expect(push.subscribed, {'trend_diesel_self'});
        expect(push.calls.first, 'permission');

        push.calls.clear();
        await syncTrendTopics(push, const {});
        expect(push.subscribed, isEmpty);
        expect(push.calls, isNot(contains('permission')));
      },
    );

    test('senza permesso lo segnala', () async {
      final push = FakePushGateway(permission: false);
      expect(await syncTrendTopics(push, {'trend_gpl'}), isFalse);
    });

    test('senza Firebase non fa nulla', () async {
      expect(
        await syncTrendTopics(const DisabledPushGateway(), {'trend_gpl'}),
        isTrue,
      );
    });
  });

  group('messaggi', () {
    test('una tendenza diventa una notifica della lista', () {
      final n = trendMessage().toNotification();
      expect(n.kind, NotificationKind.trendDown);
      expect(n.id, 'trend-benzina-self-2026-09-23');
      expect(n.isPriceAlert, isTrue);
      expect(n.read, isFalse);
      expect(
        trendMessage(direction: 'up').toNotification().kind,
        NotificationKind.trendUp,
      );
      expect(trendMessage().route, '/andamento');
    });
  });

  group('app', () {
    setUpAll(() {
      GoogleFonts.config.allowRuntimeFetching = false;
      PackageInfo.setMockInitialValues(
        appName: 'Benzina',
        packageName: 'it.benzina.benzina',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );
    });

    testWidgets('all\'avvio si iscrive al topic del carburante', (
      tester,
    ) async {
      final push = FakePushGateway();
      await tester.pumpWidget(buildApp(push: push));
      await passSplash(tester);
      expect(push.subscribed, {'trend_benzina_self'});
    });

    testWidgets('una notifica ricevuta compare tra le notifiche', (
      tester,
    ) async {
      final push = FakePushGateway();
      await tester.pumpWidget(buildApp(push: push));
      await passSplash(tester);

      push.receivedController.add(trendMessage());
      await tester.pumpAndSettle();
      expect(find.byTooltip('Notifiche, 3 non lette'), findsOneWidget);

      await tester.tap(find.byTooltip('Notifiche, 3 non lette'));
      await tester.pumpAndSettle();
      expect(
        find.text('Media nazionale 1,819 €/l: −1,2% in 3 giorni.'),
        findsOneWidget,
      );
    });

    testWidgets('toccare la notifica apre Andamento', (tester) async {
      final push = FakePushGateway();
      await tester.pumpWidget(buildApp(push: push));
      await passSplash(tester);

      push.openedController.add(trendMessage(direction: 'up'));
      await tester.pumpAndSettle();
      expect(find.text('Andamento prezzi'), findsOneWidget);
    });

    testWidgets('disattivare gli avvisi toglie l\'iscrizione', (tester) async {
      final push = FakePushGateway();
      await tester.pumpWidget(buildApp(push: push));
      await passSplash(tester);
      expect(push.subscribed, isNotEmpty);

      await tester.tap(find.byTooltip('Impostazioni'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prezzi in salita o in discesa'));
      await tester.pumpAndSettle();
      expect(push.subscribed, isEmpty);
    });
  });
}

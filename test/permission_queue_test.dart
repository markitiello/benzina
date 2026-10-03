import 'dart:async';

import 'package:benzina/core/permission_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('le richieste di permesso partono una alla volta', () async {
    final log = <String>[];
    final first = Completer<bool>();

    final a = PermissionQueue.run(() {
      log.add('posizione');
      return first.future;
    });
    final b = PermissionQueue.run(() async {
      log.add('notifiche');
      return true;
    });

    await Future<void>.delayed(Duration.zero);
    // La seconda aspetta la risposta alla prima.
    expect(log, ['posizione']);

    first.complete(true);
    expect(await a, isTrue);
    expect(await b, isTrue);
    expect(log, ['posizione', 'notifiche']);
  });

  test('una richiesta fallita non blocca le successive', () async {
    final failed = PermissionQueue.run<bool>(() async => throw StateError('x'));
    await expectLater(failed, throwsStateError);
    expect(await PermissionQueue.run(() async => 42), 42);
  });
}

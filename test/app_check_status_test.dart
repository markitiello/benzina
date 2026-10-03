import 'package:benzina/core/app_check_status.dart';
import 'package:benzina/core/widgets/common.dart';
import 'package:benzina/data/api/benzina_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    AppCheckStatus.problem = null;
    AppCheckStatus.firstError = null;
  });

  Widget body(Object error) => MaterialApp(
    home: Scaffold(
      body: AsyncBody<int>(
        value: AsyncValue.error(error, StackTrace.empty),
        builder: (_) => const SizedBox(),
      ),
    ),
  );

  testWidgets('401: sotto l\'errore il motivo per cui manca il token', (
    tester,
  ) async {
    AppCheckStatus.problem = 'token non ottenuto: -9 — app non riconosciuta';
    await tester.pumpWidget(
      body(
        const ApiException(401, 'Non autorizzato', 'token App Check assente'),
      ),
    );
    expect(
      find.text('App Check: token non ottenuto: -9 — app non riconosciuta'),
      findsOneWidget,
    );
  });

  testWidgets('altri errori: niente dettagli di App Check', (tester) async {
    AppCheckStatus.problem = 'qualcosa';
    await tester.pumpWidget(body(const ApiException(404, 'Non trovato')));
    expect(find.textContaining('App Check:'), findsNothing);
  });

  test('dopo "Too many attempts" resta visibile il primo errore', () {
    AppCheckStatus.firstError =
        'token non ottenuto: 403 App attestation failed';
    AppCheckStatus.problem = 'token non ottenuto: Too many attempts.';
    expect(
      AppCheckStatus.summary,
      'token non ottenuto: Too many attempts. '
      '(primo errore: token non ottenuto: 403 App attestation failed)',
    );
  });
}

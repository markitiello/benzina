import 'package:benzina/core/widgets/benzina_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test.dart' show buildApp;

void main() {
  // La splash nativa mostra il logo al centro esatto dello schermo: quella di
  // Flutter deve metterlo nello stesso punto, altrimenti "salta".
  for (final (name, size, ratio, padding) in [
    (
      'iPhone',
      const Size(1170, 2532),
      3.0,
      const FakeViewPadding(top: 141, bottom: 102),
    ),
    (
      'Android',
      const Size(1080, 2400),
      3.0,
      const FakeViewPadding(top: 72, bottom: 48),
    ),
    ('iPhone SE', const Size(750, 1334), 2.0, const FakeViewPadding(top: 40)),
  ]) {
    testWidgets('splash: logo al centro dello schermo ($name)', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      tester.view.padding = padding;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 5));

      final screen = size / ratio;
      expect(
        tester.getCenter(find.byType(BenzinaLogo)),
        Offset(screen.width / 2, screen.height / 2),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    });
  }
}

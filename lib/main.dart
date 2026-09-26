import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'push/firebase_push_gateway.dart';
import 'push/push_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final push = await FirebasePushGateway.create();
  runApp(
    ProviderScope(
      overrides: [pushGatewayProvider.overrideWithValue(push)],
      child: const BenzinaApp(),
    ),
  );
}

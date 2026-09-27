import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'data/api/api_config.dart';
import 'data/api/benzina_api.dart';
import 'data/api_fuel_repository.dart';
import 'firebase/firebase_setup.dart';
import 'push/firebase_push_gateway.dart';
import 'push/push_gateway.dart';
import 'push/push_providers.dart';
import 'state/local_store.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await DeviceStore.open();
  final firebase = await initFirebase();
  final push = firebase
      ? await FirebasePushGateway.create()
      : const DisabledPushGateway();
  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        pushGatewayProvider.overrideWithValue(push),
        // Senza BENZINA_API_URL restano i dati di prova.
        if (ApiConfig.isConfigured)
          fuelRepositoryProvider.overrideWithValue(
            ApiFuelRepository(
              BenzinaApi(
                baseUrl: Uri.parse(ApiConfig.baseUrl),
                appCheckToken: firebase ? appCheckToken : null,
                apiKey: ApiConfig.apiKey,
              ),
            ),
          ),
      ],
      child: const BenzinaApp(),
    ),
  );
}

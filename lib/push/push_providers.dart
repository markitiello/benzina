import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'push_gateway.dart';

/// Sostituito in main.dart con FirebasePushGateway quando Firebase è
/// configurato; nei test resta disattivato o viene sostituito da un finto.
final pushGatewayProvider = Provider<PushGateway>(
  (ref) => const DisabledPushGateway(),
);

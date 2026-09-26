import '../data/models.dart';
import '../state/providers.dart';

/// Topic Firebase Cloud Messaging delle notifiche di tendenza. Devono
/// coincidere con quelli del backend (src/Trend/Topics.php).
String trendTopic(FuelType fuel, ServiceMode mode) => fuel.hasServiceModes
    ? 'trend_${fuel.name}_${mode.name}'
    : 'trend_${fuel.name}';

final List<String> allTrendTopics = [
  for (final fuel in FuelType.values)
    if (fuel.hasServiceModes)
      for (final mode in ServiceMode.values) trendTopic(fuel, mode)
    else
      trendTopic(fuel, ServiceMode.self),
];

/// Topic a cui il dispositivo deve essere iscritto con queste impostazioni:
/// solo quello del carburante scelto, se le notifiche di tendenza sono attive.
Set<String> desiredTopics(AppSettings settings) => settings.trendAlerts
    ? {trendTopic(settings.fuel, settings.effectiveMode)}
    : const {};

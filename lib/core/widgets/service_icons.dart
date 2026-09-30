import 'package:flutter/material.dart';

/// Icone piccole dei servizi più utili a chi fa il pieno, per le liste:
/// solo bar e bancomat (gli altri servizi sono nel dettaglio).
class ServiceIcons extends StatelessWidget {
  const ServiceIcons({
    super.key,
    required this.services,
    required this.color,
    this.size = 15,
  });

  final List<String> services;
  final Color color;
  final double size;

  /// Nome come lo comunica il gestore → (descrizione, icona).
  static const shown = <String, (String, IconData)>{
    'Food&Beverage': ('Bar', Icons.local_cafe_rounded),
    'Bancomat': ('Bancomat', Icons.atm_rounded),
  };

  static bool hasAny(List<String> services) => services.any(shown.containsKey);

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final entry in shown.entries)
        if (services.contains(entry.key)) entry.value,
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (label, icon) in items)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Tooltip(
              message: label,
              child: Icon(icon, size: size, color: color, semanticLabel: label),
            ),
          ),
      ],
    );
  }
}

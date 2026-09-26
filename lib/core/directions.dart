import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Apre l'app di navigazione predefinita verso [destination].
Future<void> openDirections(BuildContext context, LatLng destination) async {
  final url = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '${destination.latitude},${destination.longitude}',
  });
  final messenger = ScaffoldMessenger.of(context);
  final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
  if (!ok) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Impossibile aprire la navigazione.')),
    );
  }
}

Future<void> openExternal(BuildContext context, Uri url) async {
  final messenger = ScaffoldMessenger.of(context);
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Impossibile aprire il link.')),
    );
  }
}

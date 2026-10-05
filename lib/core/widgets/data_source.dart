import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../directions.dart';
import '../theme/app_colors.dart';

/// Fonte ufficiale dei prezzi: dataset open data del MIMIT (prezzi praticati
/// e anagrafica degli impianti).
final mimitDatasetUrl = Uri.https(
  'www.mimit.gov.it',
  '/it/open-data/elenco-dataset/carburanti-prezzi-praticati-e-anagrafica-degli-impianti',
);

/// Osservatorio prezzi carburanti del MIMIT, consultabile online.
final osservaprezziUrl = Uri.https('carburanti.mise.gov.it', '/');

/// Nota sulla fonte dei prezzi con il link al sito del MIMIT, sotto i dati.
/// Le regole di Google Play chiedono un link chiaro alla fonte governativa
/// e di non far sembrare l'app affiliata all'ente.
class DataSourceNote extends StatefulWidget {
  const DataSourceNote({super.key});

  @override
  State<DataSourceNote> createState() => _DataSourceNoteState();
}

class _DataSourceNoteState extends State<DataSourceNote> {
  late final _source = TapGestureRecognizer()
    ..onTap = () => openExternal(context, mimitDatasetUrl);
  late final _sources = TapGestureRecognizer()
    ..onTap = () => context.push('/fonti');

  @override
  void dispose() {
    _source.dispose();
    _sources.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final link = TextStyle(
      color: c.ink,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Text.rich(
        TextSpan(
          style: TextStyle(fontSize: 12, height: 1.45, color: c.muted),
          children: [
            const TextSpan(
              text:
                  'Prezzi comunicati dai gestori al Ministero delle Imprese '
                  'e del Made in Italy. Fonte: ',
            ),
            TextSpan(text: 'mimit.gov.it', style: link, recognizer: _source),
            const TextSpan(
              text:
                  '. Benzina è un\'app indipendente, non affiliata al MIMIT. ',
            ),
            TextSpan(text: 'Fonti dei dati', style: link, recognizer: _sources),
          ],
        ),
      ),
    );
  }
}

/// Pagina con tutte le fonti dei dati e i relativi link.
class DataSourcesScreen extends StatelessWidget {
  const DataSourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget section(String title, String body, List<(String, Uri)> links) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: TextStyle(fontSize: 14, height: 1.5, color: c.ink),
              ),
              for (final (label, url) in links)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: c.cheap,
                    ),
                    onPressed: () => openExternal(context, url),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text(label),
                  ),
                ),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Fonti dei dati')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          section(
            'Prezzi e distributori',
            'I prezzi e l\'anagrafica dei distributori sono quelli che i '
                'gestori comunicano all\'Osservatorio prezzi carburanti del '
                'Ministero delle Imprese e del Made in Italy (MIMIT), '
                'pubblicati come dati aperti. Il prezzo alla pompa può '
                'differire da quello comunicato: vale quello esposto al '
                'distributore.',
            [
              ('Dati aperti MIMIT (mimit.gov.it)', mimitDatasetUrl),
              (
                'Osservaprezzi carburanti (carburanti.mise.gov.it)',
                osservaprezziUrl,
              ),
            ],
          ),
          section(
            'Valutazioni',
            'Le stelle dei distributori sono fornite da Google.',
            const [],
          ),
          section('Mappa', 'Mappa © OpenStreetMap contributors.', [
            (
              'openstreetmap.org/copyright',
              Uri.https('www.openstreetmap.org', '/copyright'),
            ),
          ]),
          section(
            'App indipendente',
            'Benzina è un\'app indipendente: non è affiliata al MIMIT né ad '
                'altri enti pubblici e non li rappresenta.',
            const [],
          ),
        ],
      ),
    );
  }
}

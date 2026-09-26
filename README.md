# Benzina

App Flutter (iOS e Android) che, data la posizione attuale, mostra il distributore più economico nel raggio scelto, la media nazionale e l'andamento dei prezzi nel tempo.

> **Stato:** scheletro dell'app con **dati di prova**. Prezzi, distributori e recensioni sono inventati finché non sarà pronto il backend (repository separato).

## Schermate

| Percorso | Schermata |
|---|---|
| `/splash` | Caricamento con logo (segue la splash nativa) |
| `/` | **Vicino a te**: il più economico, media nazionale, altri distributori |
| `/mappa` | Mappa con i prezzi (blu sotto media, arancio sopra) |
| `/andamento` | Grafico media nazionale e della tua zona, 7 g → 1 anno |
| `/preferiti` | Distributori salvati |
| `/distributore/:id` | Dettaglio: prezzi, storico, recensioni Google |
| `/notifiche` | Avvisi prezzo e notifiche dell'app |
| `/impostazioni` | Preferenze, notifiche, versione dell'app |

Tema chiaro e scuro, automatico o scelto dalle impostazioni.

## Avvio

```sh
flutter pub get
flutter run
```

Controlli:

```sh
flutter analyze
flutter test
```

Icone e splash nativa si rigenerano da `assets/branding/` con:

```sh
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Struttura

```
lib/
  app/        MaterialApp, tema e navigazione (go_router)
  core/       colori, tema, formattazione, componenti comuni, logo
  data/       modelli, interfaccia FuelRepository, dati di prova, GPS
  state/      provider Riverpod (impostazioni, dati, preferiti, notifiche)
  features/   una cartella per schermata
```

Tutte le schermate leggono i dati da `FuelRepository` (`lib/data/fuel_repository.dart`). Per collegare il backend basta un'implementazione che chiami le API e sostituirla in `fuelRepositoryProvider`.

## Prossimi passi

- [ ] Backend: importazione giornaliera dei CSV MIMIT, storico prezzi, API.
- [ ] `FuelRepository` reale al posto di `MockFuelRepository`.
- [ ] Recensioni da Google Places tramite il backend (la chiave non va nell'app). Se si mostrano dati Google sulla mappa, passare da `flutter_map` a `google_maps_flutter`.
- [ ] Notifiche push con Firebase Cloud Messaging.
- [ ] Salvataggio di impostazioni e preferiti sul dispositivo.
- [ ] Nome della zona dalla posizione (reverse geocoding).
- [ ] Tile della mappa: i server di OpenStreetMap non sono adatti al traffico di un'app pubblicata, serve un fornitore di tile.

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

## Notifiche push

L'app avvisa quando la **media nazionale** del carburante scelto inizia a **salire o scendere**: 3 giorni di fila, almeno lo 0,5%. Le tendenze le rileva il backend dopo l'import giornaliero e le invia con **Firebase Cloud Messaging**, che raggiunge sia Android sia iOS.

- L'app si iscrive al *topic* del carburante scelto (es. `trend_benzina_self`, vedi `lib/push/push_topics.dart`) e cambia iscrizione quando cambia carburante. Si disattiva da **Impostazioni → Prezzi in salita o in discesa**.
- Le notifiche arrivate finiscono nella schermata **Notifiche**; toccandole si apre **Andamento**.
- Senza Firebase configurato l'app funziona lo stesso, senza notifiche push.

### Attivarle

1. **Progetto Firebase** ([console.firebase.google.com](https://console.firebase.google.com)): aggiungere un'app Android e una iOS con identificativo `it.benzina.benzina`.
2. **iOS**: in Firebase → Impostazioni progetto → Cloud Messaging caricare la chiave APNs (.p8) creata nell'account Apple Developer. Le capacità "Push Notifications" e "Background Modes → Remote notifications" sono già nel progetto (`ios/Runner/Runner.entitlements`, `Info.plist`).
3. **Avvio dell'app** con i dati del progetto Firebase (Impostazioni progetto → Le tue app):

   ```sh
   flutter run \
     --dart-define=FIREBASE_PROJECT_ID=... \
     --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
     --dart-define=FIREBASE_ANDROID_API_KEY=... \
     --dart-define=FIREBASE_ANDROID_APP_ID=... \
     --dart-define=FIREBASE_IOS_API_KEY=... \
     --dart-define=FIREBASE_IOS_APP_ID=...
   ```

   In alternativa si può usare `flutterfire configure`, che genera `firebase_options.dart`, e passarlo a `Firebase.initializeApp` in `lib/push/firebase_push_gateway.dart`.
4. **Backend**: `BENZINA_FCM_CREDENTIALS` con il JSON del service account Firebase; `php bin/push-test.php trend_benzina_self` manda una notifica di prova.

Nota iOS: per la chiave APNs serve un account Apple Developer a pagamento. Le notifiche si provano su un iPhone reale oppure sul simulatore (Xcode 14 o successivo su Mac con chip Apple).

## Struttura

```
lib/
  app/        MaterialApp, tema e navigazione (go_router)
  core/       colori, tema, formattazione, componenti comuni, logo
  data/       modelli, interfaccia FuelRepository, dati di prova, GPS
  state/      provider Riverpod (impostazioni, dati, preferiti, notifiche)
  push/       notifiche push (Firebase Cloud Messaging, topic di tendenza)
  features/   una cartella per schermata
```

Tutte le schermate leggono i dati da `FuelRepository` (`lib/data/fuel_repository.dart`). Per collegare il backend basta un'implementazione che chiami le API e sostituirla in `fuelRepositoryProvider`.

## Prossimi passi

- [x] Backend (repository `markitiello/backend`): import MIMIT, storico, API, notifiche di tendenza.
- [ ] `FuelRepository` reale al posto di `MockFuelRepository`.
- [ ] Recensioni da Google Places tramite il backend (la chiave non va nell'app). Se si mostrano dati Google sulla mappa, passare da `flutter_map` a `google_maps_flutter`.
- [ ] Notifiche personali (soglia di prezzo, preferiti): richiedono di registrare i dispositivi sul backend.
- [ ] Salvataggio di impostazioni e preferiti sul dispositivo.
- [ ] Nome della zona dalla posizione (reverse geocoding).
- [ ] Tile della mappa: i server di OpenStreetMap non sono adatti al traffico di un'app pubblicata, serve un fornitore di tile.

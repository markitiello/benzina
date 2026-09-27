# Benzina

App Flutter (iOS e Android) che, data la posizione attuale, mostra il distributore più economico nel raggio scelto, la media nazionale e l'andamento dei prezzi nel tempo.

> I dati vengono dal backend ([`markitiello/backend`](https://github.com/markitiello/backend)). Senza indirizzo del backend l'app usa **dati di prova** inventati: utile per lavorare sull'interfaccia.

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

## Backend

L'indirizzo del backend si passa al build; senza, l'app usa i dati di prova:

```sh
flutter run --dart-define=BENZINA_API_URL=https://api.example.it
```

### Accesso riservato all'app (Firebase App Check)

Il backend risponde solo all'app originale. A ogni richiesta l'app manda un token **Firebase App Check** (header `X-Firebase-AppCheck`). Il token lo rilascia Google dopo aver verificato l'app:
- Android: **Play Integrity**, cioè app firmata da noi e installata dal Play Store;
- iOS: **App Attest**, con DeviceCheck sui dispositivi più vecchi.

Il backend ne controlla la firma e il progetto (vedi `docs/API.md` del backend). Se riceve un 401, l'app chiede un token nuovo e riprova una volta.

Il codice è in `lib/firebase/firebase_setup.dart`, `lib/data/api/benzina_api.dart` e `lib/data/api_fuel_repository.dart`.

**Configurazione, una volta sola:**
1. Nella console Firebase, **App Check**:
   - registrare l'app Android con Play Integrity; serve l'impronta SHA-256 della chiave di firma dell'app, che si trova nella Play Console → Integrità app;
   - registrare l'app iOS con App Attest.
2. **Android**: nella Play Console collegare il progetto Google Cloud a Play Integrity (Integrità app → API Play Integrity).
3. **iOS**: l'entitlement App Attest è già in `ios/Runner/Runner.entitlements`; in Xcode aggiungere la capacità "App Attest" all'App ID.
4. **Backend**:
   - `BENZINA_APPCHECK_PROJECT_NUMBER` = numero del progetto Firebase;
   - `BENZINA_APPCHECK_APP_IDS` = gli ID delle app Android e iOS (`1:…:android:…`, `1:…:ios:…`).

**Sviluppo con il backend vero:** copiare `config/dev.example.json` in `config/dev.json`, escluso da git, e inserire la chiave (`BENZINA_API_KEYS` del backend). Poi:

```sh
flutter run --dart-define-from-file config/dev.json
```

**Sviluppo:**
- **Debug provider.** Nelle build di debug l'app usa il provider di debug di App Check. Al primo avvio il token di debug compare nel log: Logcat, oppure la console di Xcode. Va aggiunto in Firebase → App Check → Gestisci token di debug.
- **Chiave statica.** In alternativa si usa una chiave statica del backend (`BENZINA_API_KEYS`), anche senza Firebase:

  ```sh
  flutter run --dart-define=BENZINA_API_URL=http://10.0.2.2:8000 --dart-define=BENZINA_API_KEY=...
  ```

  `10.0.2.2` è il computer visto dall'emulatore Android. La chiave si estrae facilmente dall'app, quindi `scripts/build_release.sh` rifiuta le build di release che la contengono.

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

## Pubblicazione

Script in `scripts/`, configurazione di fastlane in `android/fastlane` e `ios/fastlane`. I segreti (keystore, password, chiavi, `config/release.json`) sono esclusi da git.

### Una volta sola

1. **Configurazione**: copiare `config/release.example.json` in `config/release.json` e compilarlo con l'indirizzo https del backend (`BENZINA_API_URL`) e i dati del progetto Firebase.
2. **Android, firma**: `scripts/create_android_keystore.sh` crea `android/upload-keystore.jks` e `android/key.properties`. Conservare keystore e password in un posto sicuro: senza non si pubblicano aggiornamenti. Nella Play Console attivare "Play App Signing".
3. **Android, Play Console**:
   - creare l'app `it.benzina.benzina` e caricare a mano la prima versione;
   - per fastlane: Configurazione → Accesso API → service account con permesso di rilascio, salvare la chiave JSON in `android/fastlane/play-store-key.json`.
4. **iOS**: su un Mac con Xcode:
   - impostare il team in Runner → Signing & Capabilities e creare l'app in App Store Connect;
   - per fastlane: creare una chiave API in App Store Connect (Utenti e accessi → Integrazioni) e impostare `ASC_KEY_ID`, `ASC_ISSUER_ID` e `ASC_KEY_PATH`.
5. fastlane richiede Ruby e Bundler: `gem install bundler`.

### A ogni versione

```sh
scripts/build_release.sh android --build-name 1.1.0   # solo build: .aab
scripts/build_release.sh ios --build-name 1.1.0       # solo build: .ipa (Mac)

scripts/release.sh android --build-name 1.1.0         # build + test interno Play Store
scripts/release.sh ios --build-name 1.1.0             # build + TestFlight (Mac)
```

- Gli script prima eseguono analisi e test.
- La build viene offuscata; i simboli per leggere i crash restano in `build/symbols/`.
- Il numero di build di default è il numero di commit, quindi è sempre crescente.
- Dal test interno o da TestFlight si passa alla produzione dalle console degli store. Per Android si può anche usare `cd android && bundle exec fastlane promote`, che fa un rilascio graduale al 20%.

### Con GitHub Actions

- `.github/workflows/ci.yml`: formattazione, analisi e test a ogni push.
- `.github/workflows/release.yml`: a ogni tag `v*` (es. `git tag v1.1.0 && git push --tags`):
  - costruisce l'app bundle Android firmato e lo allega all'esecuzione;
  - se c'è il secret `PLAY_STORE_JSON_KEY`, lo carica nel test interno;
  - per iOS verifica solo che l'app compili; firma e invio a TestFlight si fanno dal Mac.

  I secret necessari sono elencati all'inizio del file.

## Struttura

```
lib/
  app/        MaterialApp, tema e navigazione (go_router)
  core/       colori, tema, formattazione, componenti comuni, logo
  data/       modelli, FuelRepository (backend e dati di prova), client API, GPS
  firebase/   configurazione Firebase e App Check
  state/      provider Riverpod (impostazioni, dati, preferiti, notifiche)
  push/       notifiche push (Firebase Cloud Messaging, topic di tendenza)
  features/   una cartella per schermata
```

Tutte le schermate leggono i dati da `FuelRepository` (`lib/data/fuel_repository.dart`): `ApiFuelRepository` per il backend, `MockFuelRepository` per i dati di prova. La scelta si fa in `lib/main.dart`.

## Prossimi passi

- [x] Backend (repository `markitiello/backend`): import MIMIT, storico, API, notifiche di tendenza.
- [x] `FuelRepository` collegato al backend, con Firebase App Check.
- [x] Recensioni da Google Places tramite il backend (la chiave non va nell'app).
- [ ] Se si mostrano dati Google sulla mappa, passare da `flutter_map` a `google_maps_flutter` (termini d'uso di Google).
- [ ] Orari di apertura: il MIMIT li pubblica in un file a parte, non ancora importato dal backend.
- [ ] Notifiche personali (soglia di prezzo, preferiti): richiedono di registrare i dispositivi sul backend.
- [ ] Salvataggio di impostazioni e preferiti sul dispositivo.
- [ ] Nome della zona dalla posizione (reverse geocoding).
- [ ] Tile della mappa: i server di OpenStreetMap non sono adatti al traffico di un'app pubblicata, serve un fornitore di tile.

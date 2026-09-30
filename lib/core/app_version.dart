import 'package:package_info_plus/package_info_plus.dart';

/// Short commit della build, passato da scripts/build_release.sh
/// (`--dart-define GIT_COMMIT=...`). Vuoto con `flutter run`.
const gitCommit = String.fromEnvironment('GIT_COMMIT');

/// "1.0.412 (a1b2c3d)": MAJOR.MINOR.COMMIT e short commit (vedi
/// scripts/version.sh). Senza commit, cioè in sviluppo: "1.0.0 (sviluppo)".
String appVersionLabel(PackageInfo info, {String commit = gitCommit}) =>
    '${info.version} (${commit.isEmpty ? 'sviluppo' : commit})';

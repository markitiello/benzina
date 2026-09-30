import 'package:benzina/core/app_version.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  final info = PackageInfo(
    appName: 'Benzina',
    packageName: 'it.markitiello.benzina',
    version: '1.0.412',
    buildNumber: '412',
  );

  test('versione con lo short commit', () {
    expect(appVersionLabel(info, commit: 'a1b2c3d'), '1.0.412 (a1b2c3d)');
  });

  test('senza commit: build di sviluppo', () {
    expect(appVersionLabel(info, commit: ''), '1.0.412 (sviluppo)');
  });
}

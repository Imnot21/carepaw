import 'package:carepaw/features/app_update/data/app_update_service.dart';
import 'package:carepaw/features/app_update/domain/app_release.dart';
import 'package:carepaw/features/app_update/presentation/bloc/app_update_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Service extends Mock implements AppUpdateService {}

void main() {
  group('AppVersion', () {
    test('compares numerically, ignoring v and build suffix', () {
      expect(AppVersion.isNewer('v1.0.10', '1.0.9'), isTrue);
      expect(AppVersion.isNewer('1.0.8', '1.0.8+9'), isFalse);
      expect(AppVersion.isNewer('1.1', '1.0.9'), isTrue);
      expect(AppVersion.isNewer('1.0.7', '1.0.8'), isFalse);
      expect(AppVersion.clean('v2.0.0+5'), '2.0.0');
    });
  });

  group('AppUpdateCubit', () {
    late _Service service;

    setUp(() {
      service = _Service();
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    });

    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('offers a newer release', () async {
      when(() => service.currentVersion()).thenAnswer((_) async => '1.0.8');
      when(() => service.latest()).thenAnswer(
        (_) async => const AppRelease(version: '1.0.9', downloadUrl: 'x.apk'),
      );
      final cubit = AppUpdateCubit(service);
      await cubit.check();
      expect(cubit.state.status, AppUpdateStatus.available);
      expect(cubit.state.hasUpdate, isTrue);
      await cubit.close();
    });

    test('says up to date when versions match', () async {
      when(() => service.currentVersion()).thenAnswer((_) async => '1.0.9');
      when(() => service.latest()).thenAnswer(
        (_) async => const AppRelease(version: '1.0.9'),
      );
      final cubit = AppUpdateCubit(service);
      await cubit.check();
      expect(cubit.state.status, AppUpdateStatus.upToDate);
      expect(cubit.state.hasUpdate, isFalse);
      await cubit.close();
    });

    test('reports download progress then hands over to the installer',
        () async {
      const release = AppRelease(version: '1.0.9', downloadUrl: 'x.apk');
      when(() => service.currentVersion()).thenAnswer((_) async => '1.0.8');
      when(() => service.latest()).thenAnswer((_) async => release);
      when(() => service.install(release)).thenAnswer(
        (_) => Stream.fromIterable(const [
          UpdateProgress.downloading(0.5),
          UpdateProgress.installing(),
        ]),
      );
      final cubit = AppUpdateCubit(service);
      await cubit.check();
      final seen = <AppUpdateStatus>[];
      final sub = cubit.stream.listen((s) {
        if (seen.isEmpty || seen.last != s.status) seen.add(s.status);
      });
      cubit.install();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(seen, [
        AppUpdateStatus.downloading,
        AppUpdateStatus.installing,
      ]);
      await sub.cancel();
      await cubit.close();
    });

    test('a failed check keeps a readable message', () async {
      when(() => service.currentVersion()).thenAnswer((_) async => '1.0.8');
      when(() => service.latest()).thenAnswer((_) async => null);
      final cubit = AppUpdateCubit(service);
      await cubit.check();
      expect(cubit.state.status, AppUpdateStatus.failed);
      expect(cubit.state.message, isNotNull);
      await cubit.close();
    });
  });
}

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:carepaw/features/app_update/data/app_update_service.dart';
import 'package:carepaw/features/app_update/domain/app_release.dart';

enum AppUpdateStatus {
  idle,
  checking,
  upToDate,
  available,
  downloading,
  installing,
  failed,
}

class AppUpdateState extends Equatable {
  final AppUpdateStatus status;
  final String? currentVersion;
  final AppRelease? release;

  /// 0..1 while downloading.
  final double progress;
  final String? message;

  /// True when the last check ran by itself at launch, not from a tap.
  final bool fromLaunch;

  const AppUpdateState({
    this.status = AppUpdateStatus.idle,
    this.currentVersion,
    this.release,
    this.progress = 0,
    this.message,
    this.fromLaunch = false,
  });

  bool get hasUpdate => release != null && currentVersion != null &&
      AppVersion.isNewer(release!.version, currentVersion!);

  AppUpdateState copyWith({
    AppUpdateStatus? status,
    String? currentVersion,
    AppRelease? release,
    double? progress,
    String? message,
    bool? fromLaunch,
  }) => AppUpdateState(
    status: status ?? this.status,
    currentVersion: currentVersion ?? this.currentVersion,
    release: release ?? this.release,
    progress: progress ?? this.progress,
    message: message,
    fromLaunch: fromLaunch ?? this.fromLaunch,
  );

  @override
  List<Object?> get props =>
      [status, currentVersion, release, progress, message, fromLaunch];
}

/// Checks for and installs newer CarePaw builds.
class AppUpdateCubit extends Cubit<AppUpdateState> {
  AppUpdateCubit(this._service) : super(const AppUpdateState());

  final AppUpdateService _service;
  StreamSubscription<UpdateProgress>? _install;
  bool _launchChecked = false;

  /// Runs once per app start; failures stay silent.
  Future<void> checkOnLaunch() async {
    if (_launchChecked || !AppUpdateService.supported) return;
    _launchChecked = true;
    await check(fromLaunch: true);
  }

  Future<void> check({bool fromLaunch = false}) async {
    if (state.status == AppUpdateStatus.checking ||
        state.status == AppUpdateStatus.downloading) {
      return;
    }
    if (!AppUpdateService.supported) {
      emit(state.copyWith(
        status: AppUpdateStatus.failed,
        message: 'Updates on this device come from the app store.',
        fromLaunch: fromLaunch,
      ));
      return;
    }
    emit(state.copyWith(
      status: AppUpdateStatus.checking,
      fromLaunch: fromLaunch,
    ));
    try {
      final current = await _service.currentVersion();
      final release = await _service.latest();
      if (isClosed) return;
      if (release == null) {
        emit(state.copyWith(
          status: AppUpdateStatus.failed,
          currentVersion: current,
          message: 'Could not reach the update server. Try again later.',
        ));
        return;
      }
      final newer = AppVersion.isNewer(release.version, current);
      emit(AppUpdateState(
        status: newer ? AppUpdateStatus.available : AppUpdateStatus.upToDate,
        currentVersion: current,
        release: release,
        fromLaunch: fromLaunch,
      ));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(
        status: AppUpdateStatus.failed,
        message: 'Could not check for updates. Check your connection.',
      ));
    }
  }

  void install() {
    final release = state.release;
    if (release == null || !state.hasUpdate) return;
    _install?.cancel();
    emit(state.copyWith(status: AppUpdateStatus.downloading, progress: 0));
    _install = _service.install(release).listen((p) {
      if (isClosed) return;
      if (p.error != null) {
        emit(state.copyWith(status: AppUpdateStatus.failed, message: p.error));
      } else if (p.isInstalling) {
        emit(state.copyWith(status: AppUpdateStatus.installing, progress: 1));
      } else {
        emit(state.copyWith(
          status: AppUpdateStatus.downloading,
          progress: p.fraction,
        ));
      }
    });
  }

  @override
  Future<void> close() async {
    await _install?.cancel();
    return super.close();
  }
}

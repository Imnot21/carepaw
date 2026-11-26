import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/core/di/dependency_injection.dart';
import 'package:carepaw/core/firebase/live_changes.dart';

/// Keeps a bloc's screen in step with Firestore.
///
/// Call [watchLive] after a load with the change stream for what the screen
/// shows. Each change (bursts are folded into one) calls the reload callback,
/// which should run the last load again without showing a loading skeleton.
/// The listen stops when the bloc closes or [watchLive] is called again.
mixin LiveReload<E, S> on Bloc<E, S> {
  StreamSubscription<void>? _liveSub;
  Timer? _liveDebounce;
  Object? _liveKey;

  /// The app's [LiveChanges], or null where none is registered (tests).
  LiveChanges? get liveChanges =>
      getIt.isRegistered<LiveChanges>() ? getIt<LiveChanges>() : null;

  /// Listens to [changes] for the data identified by [key]. Calling again
  /// with the same key keeps the current listen; a new key replaces it.
  void watchLive(
    Object key,
    Stream<void> Function(LiveChanges live) changes,
    void Function() onChange,
  ) {
    final live = liveChanges;
    if (live == null || isClosed) return;
    if (_liveKey == key && _liveSub != null) return;
    _liveSub?.cancel();
    _liveKey = key;
    _liveSub = changes(live).listen((_) {
      _liveDebounce?.cancel();
      _liveDebounce = Timer(const Duration(milliseconds: 400), () {
        if (!isClosed) onChange();
      });
    });
  }

  @override
  Future<void> close() async {
    _liveDebounce?.cancel();
    await _liveSub?.cancel();
    return super.close();
  }
}

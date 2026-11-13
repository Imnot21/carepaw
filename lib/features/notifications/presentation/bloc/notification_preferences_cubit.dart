import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart';
import 'package:carepaw/features/notifications/domain/repositories/notification_repository.dart';

/// Where the notification settings screen is in its life.
enum NotificationPreferencesStatus { loading, ready, loadFailed }

/// State of the notification settings screen.
class NotificationPreferencesState extends Equatable {
  final NotificationPreferencesStatus status;

  /// The preferences shown on screen. Null until the first load finishes.
  final NotificationPreferences? preferences;

  /// Number of saves that failed. It only ever goes up, so a listener can show
  /// one message per failure.
  final int saveFailures;

  const NotificationPreferencesState({
    this.status = NotificationPreferencesStatus.loading,
    this.preferences,
    this.saveFailures = 0,
  });

  NotificationPreferencesState copyWith({
    NotificationPreferencesStatus? status,
    NotificationPreferences? preferences,
    int? saveFailures,
  }) {
    return NotificationPreferencesState(
      status: status ?? this.status,
      preferences: preferences ?? this.preferences,
      saveFailures: saveFailures ?? this.saveFailures,
    );
  }

  @override
  List<Object?> get props => [status, preferences, saveFailures];
}

/// Holds the signed-in user's notification preferences.
///
/// A change shows on screen at once and is saved in the background. If the
/// save fails, the screen goes back to the last saved value.
///
/// This is separate from `NotificationBloc` on purpose. That bloc holds one
/// state at a time, so a preferences state there replaced the notification
/// list, and a "saved" state replaced the preferences.
class NotificationPreferencesCubit extends Cubit<NotificationPreferencesState> {
  NotificationPreferencesCubit({
    required this._repository,
    required this._currentUserId,
    this.onChanged,
  }) : super(const NotificationPreferencesState());

  final NotificationRepository _repository;
  final int? Function() _currentUserId;

  /// Called with every value the screen shows, including a roll-back, so the
  /// device alerts follow the switches without waiting for a reload.
  final void Function(NotificationPreferences preferences)? onChanged;

  /// The last value Firestore accepted.
  NotificationPreferences? _saved;
  bool _saving = false;

  /// Load the signed-in user's preferences, or the defaults if none are saved.
  Future<void> load() async {
    emit(state.copyWith(status: NotificationPreferencesStatus.loading));
    final userId = _currentUserId();
    if (userId == null) {
      emit(state.copyWith(status: NotificationPreferencesStatus.loadFailed));
      return;
    }
    try {
      final found = await _repository.findPreferences(userId);
      final now = DateTime.now();
      final preferences =
          found ??
          NotificationPreferences(
            userId: userId,
            createdAt: now,
            updatedAt: now,
          );
      _saved = preferences;
      if (isClosed) return;
      emit(
        state.copyWith(
          status: NotificationPreferencesStatus.ready,
          preferences: preferences,
        ),
      );
    } catch (e) {
      debugPrint('[notification_preferences] load failed: $e');
      if (isClosed) return;
      emit(state.copyWith(status: NotificationPreferencesStatus.loadFailed));
    }
  }

  /// Apply [edit] to the current preferences and save the result.
  void change(
    NotificationPreferences Function(NotificationPreferences current) edit,
  ) {
    final current = state.preferences;
    if (current == null) return;
    final next = edit(current);
    if (next == current) return;
    emit(state.copyWith(preferences: next));
    onChanged?.call(next);
    _save();
  }

  /// Save until Firestore holds what the screen shows.
  ///
  /// Only one save runs at a time. A change made during a save is picked up by
  /// the next turn of the loop, so quick taps cannot land out of order. The
  /// loop keeps going after the screen closes, so the last tap is not lost.
  Future<void> _save() async {
    if (_saving) return;
    _saving = true;
    try {
      while (true) {
        final target = state.preferences;
        if (target == null || target == _saved) break;
        try {
          await _repository.updatePreferences(target);
          _saved = target;
        } catch (e) {
          debugPrint('[notification_preferences] save failed: $e');
          final saved = _saved;
          if (saved != null) {
            onChanged?.call(saved);
            if (!isClosed) {
              emit(
                state.copyWith(
                  preferences: saved,
                  saveFailures: state.saveFailures + 1,
                ),
              );
            }
          }
          break;
        }
      }
    } finally {
      _saving = false;
    }
  }
}

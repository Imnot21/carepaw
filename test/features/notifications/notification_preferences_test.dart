import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_switch.dart';
import 'package:carepaw/features/notifications/domain/entities/notification.dart';
import 'package:carepaw/features/notifications/domain/repositories/notification_repository.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_event.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_preferences_cubit.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_state.dart';
import 'package:carepaw/features/notifications/presentation/notification_alerts.dart';
import 'package:carepaw/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements NotificationRepository {}

class _ListBloc extends MockBloc<NotificationEvent, NotificationState>
    implements NotificationBloc {}

const _userId = 7;
final _epoch = DateTime(2026, 1, 1);

NotificationPreferences _prefs({
  bool appointmentReminders = true,
  bool queueUpdates = true,
  bool pushEnabled = true,
  bool inAppEnabled = true,
}) {
  return NotificationPreferences(
    userId: _userId,
    appointmentReminders: appointmentReminders,
    queueUpdates: queueUpdates,
    pushEnabled: pushEnabled,
    inAppEnabled: inAppEnabled,
    createdAt: _epoch,
    updatedAt: _epoch,
  );
}

void main() {
  late _Repo repo;

  setUpAll(() => registerFallbackValue(_prefs()));

  setUp(() {
    repo = _Repo();
    when(() => repo.updatePreferences(any())).thenAnswer(
      (call) async => call.positionalArguments.first as NotificationPreferences,
    );
  });

  NotificationPreferencesCubit build({
    int? userId = _userId,
    void Function(NotificationPreferences)? onChanged,
  }) {
    return NotificationPreferencesCubit(
      repository: repo,
      currentUserId: () => userId,
      onChanged: onChanged,
    );
  }

  group('NotificationPreferencesCubit', () {
    test('load shows the saved preferences', () async {
      final saved = _prefs(queueUpdates: false);
      when(() => repo.findPreferences(_userId)).thenAnswer((_) async => saved);
      final cubit = build();

      await cubit.load();

      expect(cubit.state.status, NotificationPreferencesStatus.ready);
      expect(cubit.state.preferences, saved);
    });

    test('load falls back to defaults for the signed-in user', () async {
      when(() => repo.findPreferences(_userId)).thenAnswer((_) async => null);
      final cubit = build();

      await cubit.load();

      expect(cubit.state.preferences?.userId, _userId);
      expect(cubit.state.preferences?.queueUpdates, isTrue);
    });

    test('load fails when nobody is signed in', () async {
      final cubit = build(userId: null);

      await cubit.load();

      expect(cubit.state.status, NotificationPreferencesStatus.loadFailed);
      verifyNever(() => repo.findPreferences(any()));
    });

    test('a change shows before the save finishes', () async {
      when(
        () => repo.findPreferences(_userId),
      ).thenAnswer((_) async => _prefs());
      final write = Completer<NotificationPreferences>();
      when(
        () => repo.updatePreferences(any()),
      ).thenAnswer((_) => write.future);
      final cubit = build();
      await cubit.load();

      cubit.change((p) => p.copyWith(queueUpdates: false));

      expect(cubit.state.preferences?.queueUpdates, isFalse);
      expect(write.isCompleted, isFalse);
      write.complete(_prefs(queueUpdates: false));
    });

    test('a change leaves the other switches alone', () async {
      // The old screen reset every switch to its default after a save.
      final saved = _prefs(appointmentReminders: false);
      when(() => repo.findPreferences(_userId)).thenAnswer((_) async => saved);
      final cubit = build();
      await cubit.load();

      cubit.change((p) => p.copyWith(queueUpdates: false));
      await pumpEventQueue();

      expect(
        cubit.state.preferences,
        saved.copyWith(queueUpdates: false),
      );
      expect(cubit.state.preferences?.appointmentReminders, isFalse);
    });

    test('a failed save goes back to the last saved value', () async {
      final saved = _prefs();
      when(() => repo.findPreferences(_userId)).thenAnswer((_) async => saved);
      when(
        () => repo.updatePreferences(any()),
      ).thenThrow(Exception('offline'));
      final seen = <NotificationPreferences>[];
      final cubit = build(onChanged: seen.add);
      await cubit.load();

      cubit.change((p) => p.copyWith(queueUpdates: false));
      await pumpEventQueue();

      expect(cubit.state.preferences, saved);
      expect(cubit.state.saveFailures, 1);
      expect(seen.last, saved);
    });

    test('quick taps save in order and the last one wins', () async {
      when(
        () => repo.findPreferences(_userId),
      ).thenAnswer((_) async => _prefs());
      final firstWrite = Completer<NotificationPreferences>();
      final written = <NotificationPreferences>[];
      when(() => repo.updatePreferences(any())).thenAnswer((call) {
        final value = call.positionalArguments.first as NotificationPreferences;
        written.add(value);
        return written.length == 1 ? firstWrite.future : Future.value(value);
      });
      final cubit = build();
      await cubit.load();

      cubit.change((p) => p.copyWith(queueUpdates: false));
      cubit.change((p) => p.copyWith(appointmentReminders: false));
      expect(written, hasLength(1));
      firstWrite.complete(written.first);
      await pumpEventQueue();

      expect(written, hasLength(2));
      expect(written.last.queueUpdates, isFalse);
      expect(written.last.appointmentReminders, isFalse);
    });
  });

  group('NotificationAlerts.allows', () {
    test('shows everything when no preferences are saved', () {
      expect(
        NotificationAlerts.allows(null, NotificationType.queueUpdate),
        isTrue,
      );
    });

    test('mutes only the category that is off', () {
      final preferences = _prefs(queueUpdates: false);

      expect(
        NotificationAlerts.allows(preferences, NotificationType.queueUpdate),
        isFalse,
      );
      expect(
        NotificationAlerts.allows(
          preferences,
          NotificationType.appointmentReminder,
        ),
        isTrue,
      );
    });

    test('mutes everything when either master flag is off', () {
      for (final preferences in [
        _prefs(pushEnabled: false),
        _prefs(inAppEnabled: false),
      ]) {
        expect(
          NotificationAlerts.allows(
            preferences,
            NotificationType.appointmentReminder,
          ),
          isFalse,
        );
      }
    });
  });

  group('NotificationSettingsPage', () {
    late NotificationPreferencesCubit cubit;
    late _ListBloc listBloc;

    Future<void> pumpPage(
      WidgetTester tester,
      NotificationPreferences saved,
    ) async {
      when(() => repo.findPreferences(_userId)).thenAnswer((_) async => saved);
      cubit = build();
      listBloc = _ListBloc();
      when(() => listBloc.state).thenReturn(const NotificationInitial());
      await cubit.load();
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<NotificationBloc>.value(value: listBloc),
              BlocProvider<NotificationPreferencesCubit>.value(value: cubit),
            ],
            child: const NotificationSettingsPage(),
          ),
        ),
      );
      await tester.pump();
    }

    /// Switch values in screen order: master, appointments, queue.
    List<bool> switches(WidgetTester tester) => tester
        .widgetList<NeuSwitch>(find.byType(NeuSwitch))
        .map((s) => s.value)
        .toList();

    testWidgets('a tap flips only the row that was tapped', (tester) async {
      await pumpPage(tester, _prefs(appointmentReminders: false));
      expect(switches(tester), [true, false, true]);

      await tester.tap(find.text('Queue Updates'));
      await tester.pump();

      expect(switches(tester), [true, false, false]);
      await tester.pumpAndSettle();
      expect(switches(tester), [true, false, false]);
    });

    testWidgets('fits a small phone at a large text size in dark mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      when(
        () => repo.findPreferences(_userId),
      ).thenAnswer((_) async => _prefs());
      cubit = build();
      listBloc = _ListBloc();
      when(() => listBloc.state).thenReturn(const NotificationInitial());
      await cubit.load();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: MultiBlocProvider(
            providers: [
              BlocProvider<NotificationBloc>.value(value: listBloc),
              BlocProvider<NotificationPreferencesCubit>.value(value: cubit),
            ],
            child: const NotificationSettingsPage(),
          ),
        ),
      );
      await tester.pump();

      // A layout overflow throws in a widget test.
      expect(tester.takeException(), isNull);
      expect(find.text('Queue Updates'), findsOneWidget);
    });

    testWidgets('the master switch turns both stored flags off', (
      tester,
    ) async {
      await pumpPage(tester, _prefs());

      await tester.tap(find.text('Device Alerts'));
      await tester.pumpAndSettle();

      expect(cubit.state.preferences?.pushEnabled, isFalse);
      expect(cubit.state.preferences?.inAppEnabled, isFalse);
      // The categories keep their saved values and stop responding.
      expect(switches(tester), [false, true, true]);
      await tester.tap(find.text('Queue Updates'));
      await tester.pumpAndSettle();
      expect(cubit.state.preferences?.queueUpdates, isTrue);
    });
  });
}

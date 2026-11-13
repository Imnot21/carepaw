import 'package:carepaw/features/notifications/domain/entities/notification.dart'
    as domain;
import 'package:carepaw/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_event.dart';
import 'package:carepaw/features/notifications/presentation/bloc/notification_state.dart';
import 'package:carepaw/features/notifications/presentation/widgets/notification_list_widgets.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Bloc extends MockBloc<NotificationEvent, NotificationState>
    implements NotificationBloc {}

void main() {
  for (final read in [false, true]) {
    testWidgets('NotificationCard fits 320px at 1.6x (read: $read)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final bloc = _Bloc();
      whenListen(
        bloc,
        const Stream<NotificationState>.empty(),
        initialState: const NotificationInitial(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: BlocProvider<NotificationBloc>.value(
            value: bloc,
            child: Scaffold(
              body: SingleChildScrollView(
                child: NotificationCard(
                  notification: domain.Notification(
                    id: 1,
                    userId: 1,
                    type: domain.NotificationType.queueUpdate,
                    title: 'Your pet is next in line at the clinic today',
                    message:
                        'Please come to the front desk when you are ready.',
                    isRead: read,
                    createdAt: DateTime(2026, 1, 1),
                  ),
                  typeColor: Colors.orange,
                  typeSvg: 'assets/icons/queue.svg',
                  onViewDetails: () {},
                  onDelete: () {},
                ),
              ),
            ),
          ),
        ),
      );
      final e = tester.takeException(); if (e != null) { debugPrint(e.toString()); }
      expect(e, isNull);
    });
  }
}

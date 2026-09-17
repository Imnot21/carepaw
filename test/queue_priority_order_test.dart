import 'package:carepaw/features/queue/domain/entities/queue_entry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for the priority-first queue ordering.
///
/// Covers the canonical `[QueueEntry.byQueueOrder]` comparator — the single
/// source of truth used by repo `findAll`/`watchAll`/`callNext`/`reposition`,
/// the BLoC owner-position calculation, and the staff dashboard preview — and
/// the `[QueuePriority]` ranks that drive it.
void main() {
  QueueEntry entry({
    required int id,
    required DateTime checkedInAt,
    QueuePriority priority = QueuePriority.routine,
  }) {
    return QueueEntry(
      id: id,
      appointmentId: id,
      position: id, // arrival serial; deliberately NOT a sort key
      priority: priority,
      checkedInAt: checkedInAt,
      createdAt: checkedInAt,
      updatedAt: checkedInAt,
    );
  }

  final t1 = DateTime(2026, 1, 1, 9, 0);
  final t2 = DateTime(2026, 1, 1, 9, 5);
  final t3 = DateTime(2026, 1, 1, 9, 10);

  group('QueuePriority', () {
    test('ranks emergency above urgent above routine', () {
      expect(
        QueuePriority.emergency.rank < QueuePriority.urgent.rank,
        isTrue,
      );
      expect(
        QueuePriority.urgent.rank < QueuePriority.routine.rank,
        isTrue,
      );
    });

    test('fromString falls back to routine for unknown/missing values', () {
      expect(QueuePriority.fromString('EMERGENCY'), QueuePriority.emergency);
      expect(QueuePriority.fromString('URGENT'), QueuePriority.urgent);
      expect(QueuePriority.fromString('ROUTINE'), QueuePriority.routine);
      expect(QueuePriority.fromString('BOGUS'), QueuePriority.routine);
      expect(QueuePriority.fromString(''), QueuePriority.routine);
    });

    test('new QueueEntry defaults to routine', () {
      final e = entry(id: 1, checkedInAt: t1);
      expect(e.priority, QueuePriority.routine);
    });
  });

  group('QueueEntry.byQueueOrder', () {
    test('keeps FIFO within the same priority tier', () {
      final first = entry(id: 1, checkedInAt: t1);
      final second = entry(id: 2, checkedInAt: t2);
      expect(QueueEntry.byQueueOrder(first, second), lessThan(0));
      expect(QueueEntry.byQueueOrder(second, first), greaterThan(0));
      expect(QueueEntry.byQueueOrder(first, first), 0);
    });

    test('emergency outranks routine even when checked in later', () {
      final routine = entry(id: 1, checkedInAt: t1);
      final emergency = entry(id: 7, checkedInAt: t3,
          priority: QueuePriority.emergency);
      // Later arrival, but Emergency — must sort ahead of the earlier Routine.
      expect(QueueEntry.byQueueOrder(emergency, routine), lessThan(0));
    });

    test('sorts a mixed-tier list into priority-first order', () {
      final entries = [
        entry(id: 2, checkedInAt: t2), // routine
        entry(id: 1, checkedInAt: t1, priority: QueuePriority.urgent),
        entry(id: 4, checkedInAt: t3), // routine
        entry(id: 3, checkedInAt: t1, priority: QueuePriority.emergency),
        entry(id: 5, checkedInAt: t2, priority: QueuePriority.urgent),
      ]..sort(QueueEntry.byQueueOrder);

      expect(entries[0].id, 3); // emergency@t1
      expect(entries[1].id, 1); // urgent@t1
      expect(entries[2].id, 5); // urgent@t2
      expect(entries[3].id, 2); // routine@t2
      expect(entries[4].id, 4); // routine@t3
    });

    test('retriaging a later arrival to Emergency promotes it to #1', () {
      // Simulate the run the plan's manual walkthrough asserts: owner checks
      // in two Routine patients, then staff retriages patient #2 to Emergency.
      var patient1 = entry(id: 1, checkedInAt: t1, priority: QueuePriority.routine);
      var patient2 = entry(id: 2, checkedInAt: t2, priority: QueuePriority.routine);

      var queued = [patient1, patient2]..sort(QueueEntry.byQueueOrder);
      expect(queued.first.id, 1); // FIFO before triage

      // Staff retriages patient #2 to Emergency.
      patient2 = patient2.copyWith(priority: QueuePriority.emergency);
      queued = [patient1, patient2]..sort(QueueEntry.byQueueOrder);
      expect(queued.first.id, 2); // Emergency moves to front

      // After retriage, Routine patient #1 (earliest arrival) is last.
      expect(queued.last.id, 1);
    });
  });
}
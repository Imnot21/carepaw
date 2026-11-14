import 'package:carepaw/features/appointments/domain/clinic_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClinicSchedule', () {
    // 2026-11-14 is a Saturday.
    final saturday = DateTime(2026, 11, 14, 9, 30);
    final sunday = DateTime(2026, 11, 15, 9, 30);
    final monday = DateTime(2026, 11, 16, 9, 30);
    final friday = DateTime(2026, 11, 20, 14, 0);

    test('only Saturday and Sunday are open', () {
      expect(ClinicSchedule.isOpenDay(saturday), isTrue);
      expect(ClinicSchedule.isOpenDay(sunday), isTrue);
      expect(ClinicSchedule.isOpenDay(monday), isFalse);
      expect(ClinicSchedule.isOpenDay(friday), isFalse);
    });

    test('nextOpenDay keeps an open day as is', () {
      expect(ClinicSchedule.nextOpenDay(sunday), sunday);
    });

    test('nextOpenDay moves a weekday to Saturday, same time', () {
      expect(ClinicSchedule.nextOpenDay(monday), DateTime(2026, 11, 21, 9, 30));
      expect(ClinicSchedule.nextOpenDay(friday), DateTime(2026, 11, 21, 14, 0));
    });
  });
}

/// Days the clinic takes appointments.
///
/// PILA VET HUB opens on weekends only, so owners can book a Saturday or a
/// Sunday and nothing else.
class ClinicSchedule {
  const ClinicSchedule._();

  /// `DateTime.weekday` values the clinic is open.
  static const Set<int> openWeekdays = {DateTime.saturday, DateTime.sunday};

  /// Human-readable list of open days, for messages.
  static const String openDaysLabel = 'Saturdays and Sundays';

  static bool isOpenDay(DateTime date) => openWeekdays.contains(date.weekday);

  /// [from] itself when the clinic is open that day, otherwise the next open
  /// day at the same time of day.
  static DateTime nextOpenDay(DateTime from) {
    var date = from;
    while (!isOpenDay(date)) {
      date = DateTime(
        date.year,
        date.month,
        date.day + 1,
        date.hour,
        date.minute,
      );
    }
    return date;
  }
}

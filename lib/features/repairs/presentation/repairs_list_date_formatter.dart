class RepairsListDateFormatter {
  const RepairsListDateFormatter();

  String formatDate(DateTime value, DateTime now) {
    final localValue = value.toLocal();
    final localToday = _dateOnly(now.toLocal());
    final localDate = _dateOnly(localValue);
    final dayDifference = localToday.difference(localDate).inDays;

    if (dayDifference == 0) {
      return 'Today';
    }
    if (dayDifference == 1) {
      return 'Yesterday';
    }
    if (dayDifference > 1 && dayDifference < 30) {
      return '$dayDifference days ago';
    }

    final day = localValue.day.toString().padLeft(2, '0');
    final month = _monthNames[localValue.month - 1];
    return '$day $month ${localValue.year}';
  }

  String? formatOpenDays({
    required DateTime receivedAt,
    required DateTime now,
    required bool isFinalized,
  }) {
    if (isFinalized) {
      return null;
    }

    final localToday = _dateOnly(now.toLocal());
    final receivedDate = _dateOnly(receivedAt.toLocal());
    final openDays = localToday.difference(receivedDate).inDays;

    if (openDays < 14) {
      return null;
    }

    return 'Open $openDays days';
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

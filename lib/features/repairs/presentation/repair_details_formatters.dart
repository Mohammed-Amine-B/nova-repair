class RepairDetailsDateFormatter {
  const RepairDetailsDateFormatter();

  String format(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = _monthNames[local.month - 1];
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day $month ${local.year}, $hour:$minute';
  }
}

class DzdPriceFormatter {
  const DzdPriceFormatter();

  String format(int amount) {
    final raw = amount.toString();
    final buffer = StringBuffer();

    for (var index = 0; index < raw.length; index++) {
      final remaining = raw.length - index;
      buffer.write(raw[index]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(' ');
      }
    }

    return '$buffer DA';
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

class DashboardDateFormatter {
  const DashboardDateFormatter();

  String formatReceivedDate(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = _monthNames[local.month - 1];

    return '$day $month ${local.year}';
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

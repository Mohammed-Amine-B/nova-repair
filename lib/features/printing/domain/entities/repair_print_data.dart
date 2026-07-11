import 'customer_ticket_data.dart';
import 'device_label_data.dart';

class RepairPrintData {
  const RepairPrintData({
    required this.customerTicket,
    required this.deviceLabel,
  });

  final CustomerTicketData customerTicket;
  final DeviceLabelData deviceLabel;
}

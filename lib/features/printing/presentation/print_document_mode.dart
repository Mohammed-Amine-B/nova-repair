enum PrintDocumentMode {
  customerTicket,
  deviceLabel;

  String get label {
    return switch (this) {
      PrintDocumentMode.customerTicket => 'Customer Ticket',
      PrintDocumentMode.deviceLabel => 'Device Label',
    };
  }

  String get description {
    return switch (this) {
      PrintDocumentMode.customerTicket => 'Standard receipt size',
      PrintDocumentMode.deviceLabel => '40x60mm sticky label',
    };
  }

  String get paperLabel {
    return switch (this) {
      PrintDocumentMode.customerTicket => 'Receipt / A4',
      PrintDocumentMode.deviceLabel => 'Label',
    };
  }
}

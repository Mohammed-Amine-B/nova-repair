class ShopSettings {
  factory ShopSettings({
    String shopName = defaultShopName,
    String? shopSubtitle,
    String? phoneNumber,
    String? address,
    String? logoPath,
    String repairCodePrefix = defaultRepairCodePrefix,
    int repairCodeNumberWidth = defaultRepairCodeNumberWidth,
    String? ticketFooter,
    String? warrantyTerms,
    String? defaultCustomerTicketPrinterId,
    String? defaultDeviceLabelPrinterId,
    String? publicShopId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    final normalizedShopName = shopName.trim();
    final normalizedPrefix = _normalizePrefix(repairCodePrefix);

    _validateShopName(normalizedShopName);
    _validateRepairCodePrefix(normalizedPrefix);
    _validateRepairCodeNumberWidth(repairCodeNumberWidth);

    return ShopSettings._(
      shopName: normalizedShopName,
      shopSubtitle: _blankToNull(shopSubtitle),
      phoneNumber: _blankToNull(phoneNumber),
      address: _blankToNull(address),
      logoPath: _blankToNull(logoPath),
      repairCodePrefix: normalizedPrefix,
      repairCodeNumberWidth: repairCodeNumberWidth,
      ticketFooter: _blankToNull(ticketFooter),
      warrantyTerms: _blankToNull(warrantyTerms),
      defaultCustomerTicketPrinterId: _blankToNull(
        defaultCustomerTicketPrinterId,
      ),
      defaultDeviceLabelPrinterId: _blankToNull(defaultDeviceLabelPrinterId),
      publicShopId: _blankToNull(publicShopId),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  const ShopSettings._({
    required this.shopName,
    required this.shopSubtitle,
    required this.phoneNumber,
    required this.address,
    required this.logoPath,
    required this.repairCodePrefix,
    required this.repairCodeNumberWidth,
    required this.ticketFooter,
    required this.warrantyTerms,
    required this.defaultCustomerTicketPrinterId,
    required this.defaultDeviceLabelPrinterId,
    required this.publicShopId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShopSettings.defaults(DateTime now) {
    return ShopSettings(
      shopName: defaultShopName,
      repairCodePrefix: defaultRepairCodePrefix,
      repairCodeNumberWidth: defaultRepairCodeNumberWidth,
      createdAt: now,
      updatedAt: now,
    );
  }

  static const defaultShopName = 'My Repair Shop';
  static const defaultRepairCodePrefix = 'REP';
  static const defaultRepairCodeNumberWidth = 4;
  static const minRepairCodeNumberWidth = 3;
  static const maxRepairCodeNumberWidth = 8;
  static final RegExp _prefixPattern = RegExp(r'^[A-Z0-9]{2,10}$');

  final String shopName;
  final String? shopSubtitle;
  final String? phoneNumber;
  final String? address;
  final String? logoPath;
  final String repairCodePrefix;
  final int repairCodeNumberWidth;
  final String? ticketFooter;
  final String? warrantyTerms;
  final String? defaultCustomerTicketPrinterId;
  final String? defaultDeviceLabelPrinterId;
  final String? publicShopId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShopSettings copyWith({
    String? shopName,
    Object? shopSubtitle = _unchanged,
    Object? phoneNumber = _unchanged,
    Object? address = _unchanged,
    Object? logoPath = _unchanged,
    String? repairCodePrefix,
    int? repairCodeNumberWidth,
    Object? ticketFooter = _unchanged,
    Object? warrantyTerms = _unchanged,
    Object? defaultCustomerTicketPrinterId = _unchanged,
    Object? defaultDeviceLabelPrinterId = _unchanged,
    Object? publicShopId = _unchanged,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShopSettings(
      shopName: shopName ?? this.shopName,
      shopSubtitle: shopSubtitle == _unchanged
          ? this.shopSubtitle
          : shopSubtitle as String?,
      phoneNumber: phoneNumber == _unchanged
          ? this.phoneNumber
          : phoneNumber as String?,
      address: address == _unchanged ? this.address : address as String?,
      logoPath: logoPath == _unchanged ? this.logoPath : logoPath as String?,
      repairCodePrefix: repairCodePrefix ?? this.repairCodePrefix,
      repairCodeNumberWidth:
          repairCodeNumberWidth ?? this.repairCodeNumberWidth,
      ticketFooter: ticketFooter == _unchanged
          ? this.ticketFooter
          : ticketFooter as String?,
      warrantyTerms: warrantyTerms == _unchanged
          ? this.warrantyTerms
          : warrantyTerms as String?,
      defaultCustomerTicketPrinterId:
          defaultCustomerTicketPrinterId == _unchanged
          ? this.defaultCustomerTicketPrinterId
          : defaultCustomerTicketPrinterId as String?,
      defaultDeviceLabelPrinterId: defaultDeviceLabelPrinterId == _unchanged
          ? this.defaultDeviceLabelPrinterId
          : defaultDeviceLabelPrinterId as String?,
      publicShopId: publicShopId == _unchanged
          ? this.publicShopId
          : publicShopId as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _normalizePrefix(String value) => value.trim().toUpperCase();

  static String? _blankToNull(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static void _validateShopName(String value) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, 'shopName', 'Cannot be blank.');
    }
  }

  static void _validateRepairCodePrefix(String value) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, 'repairCodePrefix', 'Cannot be blank.');
    }
    if (!_prefixPattern.hasMatch(value)) {
      throw ArgumentError.value(
        value,
        'repairCodePrefix',
        'Use 2 to 10 Latin letters or digits.',
      );
    }
  }

  static void _validateRepairCodeNumberWidth(int value) {
    if (value < minRepairCodeNumberWidth || value > maxRepairCodeNumberWidth) {
      throw ArgumentError.value(
        value,
        'repairCodeNumberWidth',
        'Must be between $minRepairCodeNumberWidth and $maxRepairCodeNumberWidth.',
      );
    }
  }
}

const Object _unchanged = Object();

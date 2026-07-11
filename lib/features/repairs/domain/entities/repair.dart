import '../customer_price_decision.dart';
import '../repair_status.dart';

class Repair {
  Repair({
    this.id,
    required this.repairCode,
    this.customerName,
    this.customerPhone,
    this.deviceType,
    this.brand,
    this.model,
    required this.reportedProblem,
    this.receivedAccessories,
    this.deviceAccessInfo,
    this.status = RepairStatus.received,
    this.priceAmount,
    this.customerPriceDecision = CustomerPriceDecision.notRequested,
    this.internalNotes,
    this.customerMessage,
    this.parentRepairId,
    this.trackingToken,
    required this.createdAt,
    required this.updatedAt,
    required this.receivedAt,
    this.readyAt,
    this.deliveredAt,
  }) {
    _validate();
  }

  final int? id;
  final String repairCode;
  final String? customerName;
  final String? customerPhone;
  final String? deviceType;
  final String? brand;
  final String? model;
  final String reportedProblem;
  final String? receivedAccessories;

  /// Internal-only device access details such as a PIN, password, or pattern.
  /// This must not be printed or exposed through customer-facing surfaces.
  final String? deviceAccessInfo;

  final RepairStatus status;

  /// Integer DZD amount with no decimal places.
  final int? priceAmount;

  final CustomerPriceDecision customerPriceDecision;
  final String? internalNotes;
  final String? customerMessage;
  final int? parentRepairId;
  final String? trackingToken;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime receivedAt;
  final DateTime? readyAt;
  final DateTime? deliveredAt;

  void _validate() {
    if (repairCode.trim().isEmpty) {
      throw ArgumentError.value(repairCode, 'repairCode', 'Cannot be blank.');
    }
    if (reportedProblem.trim().isEmpty) {
      throw ArgumentError.value(
        reportedProblem,
        'reportedProblem',
        'Cannot be blank.',
      );
    }
    if (priceAmount != null && priceAmount! < 0) {
      throw ArgumentError.value(
        priceAmount,
        'priceAmount',
        'Cannot be negative.',
      );
    }
    if (id != null && parentRepairId == id) {
      throw ArgumentError.value(
        parentRepairId,
        'parentRepairId',
        'Cannot reference the same repair.',
      );
    }
    if (trackingToken != null && trackingToken!.trim().isEmpty) {
      throw ArgumentError.value(
        trackingToken,
        'trackingToken',
        'Cannot be blank.',
      );
    }
  }
}

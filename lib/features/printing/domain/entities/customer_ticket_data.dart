import '../../../repairs/domain/customer_price_decision.dart';
import '../../../repairs/domain/repair_status.dart';

class CustomerTicketData {
  const CustomerTicketData({
    required this.shopName,
    required this.shopSubtitle,
    required this.shopPhone,
    required this.shopAddress,
    required this.logoPath,
    required this.ticketFooter,
    required this.warrantyTerms,
    required this.repairCode,
    this.qrPayload,
    required this.receivedAt,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.deviceDisplayName,
    required this.deviceType,
    required this.reportedProblem,
    required this.receivedAccessories,
    required this.priceAmount,
    required this.customerPriceDecision,
    required this.isWarrantyReturn,
    required this.originalRepairCode,
  });

  final String shopName;
  final String? shopSubtitle;
  final String? shopPhone;
  final String? shopAddress;
  final String? logoPath;
  final String? ticketFooter;
  final String? warrantyTerms;
  final String repairCode;
  final String? qrPayload;
  final DateTime receivedAt;
  final RepairStatus status;
  final String? customerName;
  final String? customerPhone;
  final String deviceDisplayName;
  final String? deviceType;
  final String reportedProblem;
  final String? receivedAccessories;
  final int? priceAmount;
  final CustomerPriceDecision customerPriceDecision;
  final bool isWarrantyReturn;
  final String? originalRepairCode;
}

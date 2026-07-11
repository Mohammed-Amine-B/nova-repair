import '../../repairs/domain/repair_status.dart';
import 'public_tracking_contract.dart';

class PublicRepairTrackingSnapshot {
  const PublicRepairTrackingSnapshot({
    this.contractVersion = PublicTrackingContract.currentVersion,
    required this.trackingToken,
    required this.publicShopId,
    required this.shopName,
    this.shopSubtitle,
    required this.repairCode,
    required this.deviceDisplayName,
    required this.status,
    this.customerMessage,
    required this.receivedAt,
    required this.updatedAt,
  });

  final int contractVersion;
  final String trackingToken;
  final String publicShopId;
  final String shopName;
  final String? shopSubtitle;
  final String repairCode;
  final String deviceDisplayName;
  final RepairStatus status;
  final String? customerMessage;
  final DateTime receivedAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() {
    return {
      'contractVersion': contractVersion,
      'trackingToken': trackingToken,
      'shop': {
        'publicId': publicShopId,
        'name': shopName,
        'subtitle': shopSubtitle,
      },
      'repair': {
        'code': repairCode,
        'device': deviceDisplayName,
        'status': PublicTrackingContract.statusToWireValue(status),
        'customerMessage': customerMessage,
        'receivedAt': receivedAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      },
    };
  }

  factory PublicRepairTrackingSnapshot.fromJson(Map<String, Object?> json) {
    final shop = Map<String, Object?>.from(json['shop'] as Map);
    final repair = Map<String, Object?>.from(json['repair'] as Map);

    return PublicRepairTrackingSnapshot(
      contractVersion: json['contractVersion'] as int,
      trackingToken: json['trackingToken'] as String,
      publicShopId: shop['publicId'] as String,
      shopName: shop['name'] as String,
      shopSubtitle: shop['subtitle'] as String?,
      repairCode: repair['code'] as String,
      deviceDisplayName: repair['device'] as String,
      status: PublicTrackingContract.statusFromWireValue(
        repair['status'] as String,
      ),
      customerMessage: repair['customerMessage'] as String?,
      receivedAt: DateTime.parse(repair['receivedAt'] as String).toUtc(),
      updatedAt: DateTime.parse(repair['updatedAt'] as String).toUtc(),
    );
  }
}

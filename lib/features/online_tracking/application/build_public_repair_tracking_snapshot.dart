import '../../repairs/domain/entities/repair.dart';
import '../../repairs/domain/services/device_display_name_formatter.dart';
import '../../settings/domain/entities/shop_settings.dart';
import '../domain/public_repair_tracking_snapshot.dart';
import '../domain/public_tracking_identity.dart';

class BuildPublicRepairTrackingSnapshot {
  const BuildPublicRepairTrackingSnapshot({
    DeviceDisplayNameFormatter deviceDisplayNameFormatter =
        const DeviceDisplayNameFormatter(),
  }) : _deviceDisplayNameFormatter = deviceDisplayNameFormatter;

  final DeviceDisplayNameFormatter _deviceDisplayNameFormatter;

  PublicRepairTrackingSnapshot call({
    required Repair repair,
    required ShopSettings settings,
    required PublicTrackingIdentity identity,
  }) {
    return PublicRepairTrackingSnapshot(
      trackingToken: identity.trackingToken,
      publicShopId: identity.publicShopId,
      shopName: settings.shopName,
      shopSubtitle: settings.shopSubtitle,
      repairCode: repair.repairCode,
      deviceDisplayName: _deviceDisplayNameFormatter.format(
        brand: repair.brand,
        model: repair.model,
        deviceType: repair.deviceType,
      ),
      status: repair.status,
      customerMessage: _blankToNull(repair.customerMessage),
      receivedAt: repair.receivedAt.toUtc(),
      updatedAt: repair.updatedAt.toUtc(),
    );
  }

  String? _blankToNull(String? value) {
    if (value == null) {
      return null;
    }

    return value.trim().isEmpty ? null : value;
  }
}

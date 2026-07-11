import '../../online_tracking/application/build_public_tracking_url.dart';
import '../../repairs/domain/entities/repair.dart';

class BuildRepairQrPayload {
  const BuildRepairQrPayload({
    this.trackingUrlBuilder = const BuildPublicTrackingUrl(),
  });

  final BuildPublicTrackingUrl trackingUrlBuilder;

  String call(Repair repair) {
    return trackingUrlBuilder(repair.trackingToken) ?? repair.repairCode;
  }
}

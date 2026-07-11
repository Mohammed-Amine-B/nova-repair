import '../../repairs/domain/repair_status.dart';

class PublicTrackingContract {
  const PublicTrackingContract._();

  static const int currentVersion = 1;

  static String statusToWireValue(RepairStatus status) {
    return status.databaseValue;
  }

  static RepairStatus statusFromWireValue(String value) {
    return RepairStatus.fromDatabaseValue(value);
  }
}

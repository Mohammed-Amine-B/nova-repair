import '../../../../database/app_database.dart';
import '../../domain/customer_price_decision.dart';
import '../../domain/entities/repair.dart';
import '../../domain/repair_status.dart';

extension RepairRowMapper on RepairRow {
  Repair toDomain() {
    return Repair(
      id: id,
      repairCode: repairCode,
      customerName: customerName,
      customerPhone: customerPhone,
      deviceType: deviceType,
      brand: brand,
      model: model,
      reportedProblem: reportedProblem,
      receivedAccessories: receivedAccessories,
      deviceAccessInfo: deviceAccessInfo,
      status: RepairStatus.fromDatabaseValue(status),
      priceAmount: priceAmount,
      customerPriceDecision: CustomerPriceDecision.fromDatabaseValue(
        customerPriceDecision,
      ),
      internalNotes: internalNotes,
      customerMessage: customerMessage,
      parentRepairId: parentRepairId,
      trackingToken: trackingToken,
      createdAt: createdAt.toUtc(),
      updatedAt: updatedAt.toUtc(),
      receivedAt: receivedAt.toUtc(),
      readyAt: readyAt?.toUtc(),
      deliveredAt: deliveredAt?.toUtc(),
    );
  }
}

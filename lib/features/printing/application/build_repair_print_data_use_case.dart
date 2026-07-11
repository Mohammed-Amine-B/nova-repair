import '../../repairs/domain/entities/repair.dart';
import '../../repairs/domain/errors/repair_status_workflow_exception.dart';
import '../../repairs/domain/repositories/repair_repository.dart';
import '../../repairs/domain/services/device_display_name_formatter.dart';
import '../../settings/domain/entities/shop_settings.dart';
import '../../settings/domain/repositories/shop_settings_repository.dart';
import '../domain/entities/customer_ticket_data.dart';
import '../domain/entities/device_label_data.dart';
import '../domain/entities/repair_print_data.dart';
import 'build_repair_qr_payload.dart';

class BuildRepairPrintDataUseCase {
  const BuildRepairPrintDataUseCase(
    this._repairRepository,
    this._shopSettingsRepository, {
    DeviceDisplayNameFormatter deviceDisplayNameFormatter =
        const DeviceDisplayNameFormatter(),
    BuildRepairQrPayload qrPayloadBuilder = const BuildRepairQrPayload(),
  }) : _deviceDisplayNameFormatter = deviceDisplayNameFormatter,
       _qrPayloadBuilder = qrPayloadBuilder;

  final RepairRepository _repairRepository;
  final ShopSettingsRepository _shopSettingsRepository;
  final DeviceDisplayNameFormatter _deviceDisplayNameFormatter;
  final BuildRepairQrPayload _qrPayloadBuilder;

  Future<RepairPrintData> call(int repairId) async {
    final repair = await _repairRepository.getRepairById(repairId);
    if (repair == null) {
      throw RepairNotFoundException(repairId);
    }

    final settings = await _shopSettingsRepository.getSettings();
    final originalRepair = await _loadOriginalRepair(repair);
    final deviceDisplayName = _deviceDisplayNameFormatter.format(
      brand: repair.brand,
      model: repair.model,
      deviceType: repair.deviceType,
    );

    return RepairPrintData(
      customerTicket: _buildCustomerTicket(
        repair: repair,
        settings: settings,
        deviceDisplayName: deviceDisplayName,
        originalRepair: originalRepair,
      ),
      deviceLabel: _buildDeviceLabel(
        repair: repair,
        deviceDisplayName: deviceDisplayName,
      ),
    );
  }

  Future<Repair?> _loadOriginalRepair(Repair repair) {
    final parentRepairId = repair.parentRepairId;
    if (parentRepairId == null) {
      return Future.value();
    }

    return _repairRepository.getRepairById(parentRepairId);
  }

  CustomerTicketData _buildCustomerTicket({
    required Repair repair,
    required ShopSettings settings,
    required String deviceDisplayName,
    required Repair? originalRepair,
  }) {
    return CustomerTicketData(
      shopName: settings.shopName,
      shopSubtitle: settings.shopSubtitle,
      shopPhone: settings.phoneNumber,
      shopAddress: settings.address,
      logoPath: settings.logoPath,
      ticketFooter: settings.ticketFooter,
      warrantyTerms: settings.warrantyTerms,
      repairCode: repair.repairCode,
      qrPayload: _qrPayloadBuilder(repair),
      receivedAt: repair.receivedAt.toUtc(),
      status: repair.status,
      customerName: repair.customerName,
      customerPhone: repair.customerPhone,
      deviceDisplayName: deviceDisplayName,
      deviceType: repair.deviceType,
      reportedProblem: repair.reportedProblem,
      receivedAccessories: repair.receivedAccessories,
      priceAmount: repair.priceAmount,
      customerPriceDecision: repair.customerPriceDecision,
      isWarrantyReturn: repair.parentRepairId != null,
      originalRepairCode: originalRepair?.repairCode,
    );
  }

  DeviceLabelData _buildDeviceLabel({
    required Repair repair,
    required String deviceDisplayName,
  }) {
    return DeviceLabelData(
      repairCode: repair.repairCode,
      receivedAt: repair.receivedAt.toUtc(),
      deviceDisplayName: deviceDisplayName,
      customerName: repair.customerName,
      customerPhone: repair.customerPhone,
      reportedProblem: repair.reportedProblem,
    );
  }
}

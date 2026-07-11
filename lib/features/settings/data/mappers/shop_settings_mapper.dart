import '../../../../database/app_database.dart';
import '../../domain/entities/shop_settings.dart';

extension ShopSettingsRowMapper on ShopSettingsRow {
  ShopSettings toDomain() {
    return ShopSettings(
      shopName: shopName,
      shopSubtitle: shopSubtitle,
      phoneNumber: phoneNumber,
      address: address,
      logoPath: logoPath,
      repairCodePrefix: repairCodePrefix,
      repairCodeNumberWidth: repairCodeNumberWidth,
      ticketFooter: ticketFooter,
      warrantyTerms: warrantyTerms,
      defaultCustomerTicketPrinterId: defaultCustomerTicketPrinterId,
      defaultDeviceLabelPrinterId: defaultDeviceLabelPrinterId,
      publicShopId: publicShopId,
      createdAt: createdAt.toUtc(),
      updatedAt: updatedAt.toUtc(),
    );
  }
}

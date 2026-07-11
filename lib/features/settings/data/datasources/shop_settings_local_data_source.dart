import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';
import '../../domain/entities/shop_settings.dart';

const shopSettingsSingletonId = 1;

class ShopSettingsLocalDataSource {
  const ShopSettingsLocalDataSource(this._database);

  final AppDatabase _database;

  Future<ShopSettingsRow?> getSettingsRow() {
    return (_database.select(_database.shopSettingsTable)
          ..where((row) => row.id.equals(shopSettingsSingletonId)))
        .getSingleOrNull();
  }

  Future<void> saveSettings(ShopSettings settings) {
    return _database.transaction(() async {
      await upsertSettings(settings);
    });
  }

  Future<void> upsertSettings(ShopSettings settings) {
    final companion = _toCompanion(settings);

    return _database
        .into(_database.shopSettingsTable)
        .insertOnConflictUpdate(companion);
  }

  ShopSettingsTableCompanion _toCompanion(ShopSettings settings) {
    return ShopSettingsTableCompanion.insert(
      id: const Value(shopSettingsSingletonId),
      shopName: settings.shopName,
      shopSubtitle: Value(settings.shopSubtitle),
      phoneNumber: Value(settings.phoneNumber),
      address: Value(settings.address),
      logoPath: Value(settings.logoPath),
      repairCodePrefix: settings.repairCodePrefix,
      repairCodeNumberWidth: settings.repairCodeNumberWidth,
      ticketFooter: Value(settings.ticketFooter),
      warrantyTerms: Value(settings.warrantyTerms),
      defaultCustomerTicketPrinterId: Value(
        settings.defaultCustomerTicketPrinterId,
      ),
      defaultDeviceLabelPrinterId: Value(settings.defaultDeviceLabelPrinterId),
      publicShopId: Value(settings.publicShopId),
      createdAt: settings.createdAt.toUtc(),
      updatedAt: settings.updatedAt.toUtc(),
    );
  }
}

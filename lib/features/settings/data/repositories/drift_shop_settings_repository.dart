import '../../domain/entities/shop_settings.dart';
import '../../domain/repositories/shop_settings_repository.dart';
import '../datasources/shop_settings_local_data_source.dart';
import '../mappers/shop_settings_mapper.dart';
import '../../../online_tracking/infrastructure/public_shop_id_generator.dart';

class DriftShopSettingsRepository implements ShopSettingsRepository {
  DriftShopSettingsRepository(
    this._localDataSource, {
    PublicShopIdGenerator? publicShopIdGenerator,
    DateTime Function()? now,
  }) : _publicShopIdGenerator =
           publicShopIdGenerator ?? PublicShopIdGenerator(),
       _now = now ?? DateTime.now;

  final ShopSettingsLocalDataSource _localDataSource;
  final PublicShopIdGenerator _publicShopIdGenerator;
  final DateTime Function() _now;

  @override
  Future<ShopSettings> getSettings() async {
    final row = await _localDataSource.getSettingsRow();
    if (row != null) {
      final settings = row.toDomain();
      if (settings.publicShopId != null) {
        return settings;
      }

      final initialized = settings.copyWith(
        publicShopId: _publicShopIdGenerator.generate(),
        updatedAt: _now().toUtc(),
      );
      await _localDataSource.saveSettings(initialized);
      return initialized;
    }

    final defaults = ShopSettings.defaults(
      _now().toUtc(),
    ).copyWith(publicShopId: _publicShopIdGenerator.generate());
    await _localDataSource.saveSettings(defaults);
    return defaults;
  }

  @override
  Future<ShopSettings> saveSettings(ShopSettings settings) async {
    final existing = await getSettings();
    final normalizedSettings = settings.copyWith(
      publicShopId: settings.publicShopId ?? existing.publicShopId,
      createdAt: existing.createdAt,
      updatedAt: _now().toUtc(),
    );

    await _localDataSource.saveSettings(normalizedSettings);
    return normalizedSettings;
  }
}

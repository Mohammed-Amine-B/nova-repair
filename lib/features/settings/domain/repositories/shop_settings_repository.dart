import '../entities/shop_settings.dart';

abstract class ShopSettingsRepository {
  Future<ShopSettings> getSettings();

  Future<ShopSettings> saveSettings(ShopSettings settings);
}

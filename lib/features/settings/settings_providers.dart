import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../online_tracking/online_tracking_providers.dart';
import 'data/datasources/shop_settings_local_data_source.dart';
import 'data/repositories/drift_shop_settings_repository.dart';
import 'domain/repositories/shop_settings_repository.dart';

final shopSettingsLocalDataSourceProvider =
    Provider<ShopSettingsLocalDataSource>((ref) {
      return ShopSettingsLocalDataSource(ref.watch(appDatabaseProvider));
    });

final shopSettingsRepositoryProvider = Provider<ShopSettingsRepository>((ref) {
  return DriftShopSettingsRepository(
    ref.watch(shopSettingsLocalDataSourceProvider),
    publicShopIdGenerator: ref.watch(publicShopIdGeneratorProvider),
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../online_tracking/online_tracking_providers.dart';
import '../settings/settings_providers.dart';
import 'application/change_repair_status_use_case.dart';
import 'application/clear_repair_price_use_case.dart';
import 'application/create_repair_use_case.dart';
import 'application/create_warranty_return_use_case.dart';
import 'application/propose_repair_price_use_case.dart';
import 'application/record_customer_price_decision_use_case.dart';
import 'application/update_repair_use_case.dart';
import 'data/datasources/repair_code_sequence_local_data_source.dart';
import 'data/datasources/repair_local_data_source.dart';
import 'data/repositories/drift_repair_repository.dart';
import 'domain/repositories/repair_repository.dart';

final repairLocalDataSourceProvider = Provider<RepairLocalDataSource>((ref) {
  return RepairLocalDataSource(ref.watch(appDatabaseProvider));
});

final repairCodeSequenceLocalDataSourceProvider =
    Provider<RepairCodeSequenceLocalDataSource>((ref) {
      return RepairCodeSequenceLocalDataSource(ref.watch(appDatabaseProvider));
    });

final repairRepositoryProvider = Provider<RepairRepository>((ref) {
  return DriftRepairRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(repairLocalDataSourceProvider),
    ref.watch(repairCodeSequenceLocalDataSourceProvider),
    ref.watch(shopSettingsLocalDataSourceProvider),
    trackingTokenGenerator: ref.watch(trackingTokenGeneratorProvider),
    trackingSyncOutboxLocalDataSource: ref.watch(
      trackingSyncOutboxLocalDataSourceProvider,
    ),
  );
});

final createRepairUseCaseProvider = Provider<CreateRepairUseCase>((ref) {
  return CreateRepairUseCase(ref.watch(repairRepositoryProvider));
});

final createWarrantyReturnUseCaseProvider =
    Provider<CreateWarrantyReturnUseCase>((ref) {
      return CreateWarrantyReturnUseCase(ref.watch(repairRepositoryProvider));
    });

final updateRepairUseCaseProvider = Provider<UpdateRepairUseCase>((ref) {
  return UpdateRepairUseCase(ref.watch(repairRepositoryProvider));
});

final changeRepairStatusUseCaseProvider = Provider<ChangeRepairStatusUseCase>((
  ref,
) {
  return ChangeRepairStatusUseCase(ref.watch(repairRepositoryProvider));
});

final proposeRepairPriceUseCaseProvider = Provider<ProposeRepairPriceUseCase>((
  ref,
) {
  return ProposeRepairPriceUseCase(ref.watch(repairRepositoryProvider));
});

final clearRepairPriceUseCaseProvider = Provider<ClearRepairPriceUseCase>((
  ref,
) {
  return ClearRepairPriceUseCase(ref.watch(repairRepositoryProvider));
});

final recordCustomerPriceDecisionUseCaseProvider =
    Provider<RecordCustomerPriceDecisionUseCase>((ref) {
      return RecordCustomerPriceDecisionUseCase(
        ref.watch(repairRepositoryProvider),
      );
    });

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import 'application/create_common_problem_use_case.dart';
import 'application/delete_common_problem_use_case.dart';
import 'application/increment_common_problem_usage_use_case.dart';
import 'application/update_common_problem_use_case.dart';
import 'data/datasources/common_problem_local_data_source.dart';
import 'data/repositories/drift_common_problem_repository.dart';
import 'domain/repositories/common_problem_repository.dart';

final commonProblemLocalDataSourceProvider =
    Provider<CommonProblemLocalDataSource>((ref) {
      return CommonProblemLocalDataSource(ref.watch(appDatabaseProvider));
    });

final commonProblemRepositoryProvider = Provider<CommonProblemRepository>((
  ref,
) {
  return DriftCommonProblemRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(commonProblemLocalDataSourceProvider),
  );
});

final createCommonProblemUseCaseProvider = Provider<CreateCommonProblemUseCase>(
  (ref) {
    return CreateCommonProblemUseCase(
      ref.watch(commonProblemRepositoryProvider),
    );
  },
);

final updateCommonProblemUseCaseProvider = Provider<UpdateCommonProblemUseCase>(
  (ref) {
    return UpdateCommonProblemUseCase(
      ref.watch(commonProblemRepositoryProvider),
    );
  },
);

final deleteCommonProblemUseCaseProvider = Provider<DeleteCommonProblemUseCase>(
  (ref) {
    return DeleteCommonProblemUseCase(
      ref.watch(commonProblemRepositoryProvider),
    );
  },
);

final incrementCommonProblemUsageUseCaseProvider =
    Provider<IncrementCommonProblemUsageUseCase>((ref) {
      return IncrementCommonProblemUsageUseCase(
        ref.watch(commonProblemRepositoryProvider),
      );
    });

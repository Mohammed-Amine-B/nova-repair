import '../../../../database/app_database.dart';
import '../../domain/entities/common_problem.dart';

extension CommonProblemRowMapper on CommonProblemRow {
  CommonProblem toDomain() {
    return CommonProblem(
      id: id,
      title: title,
      usageCount: usageCount,
      createdAt: createdAt.toUtc(),
      updatedAt: updatedAt.toUtc(),
    );
  }
}

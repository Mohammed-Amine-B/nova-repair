import '../../../../database/app_database.dart';
import '../../domain/entities/common_problem.dart';
import '../../domain/entities/create_common_problem_input.dart';
import '../../domain/entities/update_common_problem_input.dart';
import '../../domain/errors/common_problem_exception.dart';
import '../../domain/repositories/common_problem_repository.dart';
import '../../domain/services/common_problem_title_normalizer.dart';
import '../datasources/common_problem_local_data_source.dart';
import '../mappers/common_problem_mapper.dart';

class DriftCommonProblemRepository implements CommonProblemRepository {
  const DriftCommonProblemRepository(
    this._database,
    this._localDataSource, {
    DateTime Function()? now,
    CommonProblemTitleNormalizer normalizer =
        const CommonProblemTitleNormalizer(),
  }) : _now = now ?? DateTime.now,
       _normalizer = normalizer;

  final AppDatabase _database;
  final CommonProblemLocalDataSource _localDataSource;
  final DateTime Function() _now;
  final CommonProblemTitleNormalizer _normalizer;

  @override
  Future<CommonProblem> createCommonProblem(CreateCommonProblemInput input) {
    return _database.transaction(() async {
      final title = input.normalizedTitle;
      final normalizedTitle = _normalizer.normalizeForDuplicateCheck(title);
      await _ensureUnique(normalizedTitle: normalizedTitle, title: title);

      final now = _now().toUtc();
      final id = await _localDataSource.insertCommonProblem(
        title: title,
        normalizedTitle: normalizedTitle,
        createdAt: now,
        updatedAt: now,
      );

      return _loadOrThrow(id);
    });
  }

  @override
  Future<CommonProblem> updateCommonProblemTitle(
    UpdateCommonProblemInput input,
  ) {
    return _database.transaction(() async {
      final current = await _localDataSource.getById(input.id);
      if (current == null) {
        throw CommonProblemNotFoundException(input.id);
      }

      final title = input.normalizedTitle;
      final normalizedTitle = _normalizer.normalizeForDuplicateCheck(title);
      await _ensureUnique(
        normalizedTitle: normalizedTitle,
        title: title,
        allowedId: input.id,
      );

      final updated = await _localDataSource.updateTitle(
        id: input.id,
        title: title,
        normalizedTitle: normalizedTitle,
        updatedAt: _now().toUtc(),
      );
      if (updated != 1) {
        throw CommonProblemNotFoundException(input.id);
      }

      return _loadOrThrow(input.id);
    });
  }

  @override
  Future<void> deleteCommonProblem(int id) {
    return _database.transaction(() async {
      final deleted = await _localDataSource.deleteCommonProblem(id);
      if (deleted != 1) {
        throw CommonProblemNotFoundException(id);
      }
    });
  }

  @override
  Future<CommonProblem?> getCommonProblemById(int id) async {
    final row = await _localDataSource.getById(id);
    return row?.toDomain();
  }

  @override
  Future<List<CommonProblem>> listCommonProblems() async {
    final rows = await _localDataSource.listCommonProblems();
    return [for (final row in rows) row.toDomain()];
  }

  @override
  Future<List<CommonProblem>> searchCommonProblems(String query) async {
    final rows = await _localDataSource.searchCommonProblems(query);
    return [for (final row in rows) row.toDomain()];
  }

  @override
  Future<CommonProblem> incrementUsage(int id) {
    return _database.transaction(() async {
      final updated = await _localDataSource.incrementUsage(
        id: id,
        updatedAt: _now().toUtc(),
      );
      if (updated != 1) {
        throw CommonProblemNotFoundException(id);
      }

      return _loadOrThrow(id);
    });
  }

  Future<CommonProblem> _loadOrThrow(int id) async {
    final row = await _localDataSource.getById(id);
    if (row == null) {
      throw CommonProblemNotFoundException(id);
    }

    return row.toDomain();
  }

  Future<void> _ensureUnique({
    required String normalizedTitle,
    required String title,
    int? allowedId,
  }) async {
    final existing = await _localDataSource.getByNormalizedTitle(
      normalizedTitle,
    );
    if (existing != null && existing.id != allowedId) {
      throw DuplicateCommonProblemTitleException(title);
    }
  }
}

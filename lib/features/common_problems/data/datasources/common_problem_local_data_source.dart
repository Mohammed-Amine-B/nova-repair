import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';

class CommonProblemLocalDataSource {
  const CommonProblemLocalDataSource(this._database);

  final AppDatabase _database;

  Future<int> insertCommonProblem({
    required String title,
    required String normalizedTitle,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return _database
        .into(_database.commonProblems)
        .insert(
          CommonProblemsCompanion.insert(
            title: title,
            normalizedTitle: normalizedTitle,
            usageCount: 0,
            createdAt: createdAt.toUtc(),
            updatedAt: updatedAt.toUtc(),
          ),
        );
  }

  Future<int> updateTitle({
    required int id,
    required String title,
    required String normalizedTitle,
    required DateTime updatedAt,
  }) {
    return (_database.update(
      _database.commonProblems,
    )..where((row) => row.id.equals(id))).write(
      CommonProblemsCompanion(
        title: Value(title),
        normalizedTitle: Value(normalizedTitle),
        updatedAt: Value(updatedAt.toUtc()),
      ),
    );
  }

  Future<int> deleteCommonProblem(int id) {
    return (_database.delete(
      _database.commonProblems,
    )..where((row) => row.id.equals(id))).go();
  }

  Future<CommonProblemRow?> getById(int id) {
    return (_database.select(
      _database.commonProblems,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
  }

  Future<CommonProblemRow?> getByNormalizedTitle(String normalizedTitle) {
    return (_database.select(_database.commonProblems)
          ..where((row) => row.normalizedTitle.equals(normalizedTitle)))
        .getSingleOrNull();
  }

  Future<List<CommonProblemRow>> listCommonProblems() {
    return (_database.select(_database.commonProblems)..orderBy([
          (row) =>
              OrderingTerm(expression: row.usageCount, mode: OrderingMode.desc),
          (row) =>
              OrderingTerm(expression: row.updatedAt, mode: OrderingMode.desc),
          (row) => OrderingTerm(expression: row.id, mode: OrderingMode.asc),
        ]))
        .get();
  }

  Future<List<CommonProblemRow>> searchCommonProblems(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return listCommonProblems();
    }

    final escaped = _escapeLike(trimmed.toLowerCase());
    final pattern = '%$escaped%';

    return (_database.select(_database.commonProblems)
          ..where(
            (row) =>
                row.title.lower().like(pattern, escapeChar: r'\') |
                row.normalizedTitle.like(pattern, escapeChar: r'\'),
          )
          ..orderBy([
            (row) => OrderingTerm(
              expression: row.usageCount,
              mode: OrderingMode.desc,
            ),
            (row) => OrderingTerm(
              expression: row.updatedAt,
              mode: OrderingMode.desc,
            ),
            (row) => OrderingTerm(expression: row.id, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<int> incrementUsage({required int id, required DateTime updatedAt}) {
    return _database.customUpdate(
      '''
UPDATE common_problems
SET usage_count = usage_count + 1,
    updated_at = ?
WHERE id = ?
''',
      variables: [Variable<DateTime>(updatedAt.toUtc()), Variable<int>(id)],
      updates: {_database.commonProblems},
    );
  }
}

String _escapeLike(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

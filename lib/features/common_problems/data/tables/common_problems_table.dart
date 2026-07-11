import 'package:drift/drift.dart';

@DataClassName('CommonProblemRow')
class CommonProblems extends Table {
  @override
  String get tableName => 'common_problems';

  IntColumn get id => integer().autoIncrement()();

  TextColumn get title =>
      text().customConstraint('NOT NULL CHECK(length(trim(title)) > 0)')();

  TextColumn get normalizedTitle => text().customConstraint(
    'NOT NULL UNIQUE CHECK(length(trim(normalized_title)) > 0)',
  )();

  IntColumn get usageCount =>
      integer().customConstraint('NOT NULL CHECK(usage_count >= 0)')();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();
}

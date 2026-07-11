import 'package:drift/drift.dart';

@DataClassName('RepairCodeSequenceRow')
class RepairCodeSequenceTable extends Table {
  @override
  String get tableName => 'repair_code_sequence';

  @override
  List<String> get customConstraints => const ['CHECK(id = 1)'];

  IntColumn get id => integer().autoIncrement()();

  IntColumn get lastUsedSequence =>
      integer().customConstraint('NOT NULL CHECK(last_used_sequence >= 0)')();
}

import 'package:drift/drift.dart';

@DataClassName('RepairRow')
class Repairs extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get repairCode => text().unique()();

  TextColumn get customerName => text().nullable()();

  TextColumn get customerPhone => text().nullable()();

  TextColumn get deviceType => text().nullable()();

  TextColumn get brand => text().nullable()();

  TextColumn get model => text().nullable()();

  TextColumn get reportedProblem => text()();

  TextColumn get receivedAccessories => text().nullable()();

  TextColumn get deviceAccessInfo => text().nullable()();

  TextColumn get status => text()();

  IntColumn get priceAmount =>
      integer().nullable().customConstraint('NULL CHECK(price_amount >= 0)')();

  TextColumn get customerPriceDecision =>
      text().withDefault(const Constant('not_requested'))();

  TextColumn get internalNotes => text().nullable()();

  TextColumn get customerMessage => text().nullable()();

  IntColumn get parentRepairId => integer().nullable().customConstraint(
    'NULL REFERENCES repairs(id) ON UPDATE RESTRICT ON DELETE RESTRICT',
  )();

  TextColumn get trackingToken => text().nullable().unique()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get receivedAt => dateTime()();

  DateTimeColumn get readyAt => dateTime().nullable()();

  DateTimeColumn get deliveredAt => dateTime().nullable()();
}

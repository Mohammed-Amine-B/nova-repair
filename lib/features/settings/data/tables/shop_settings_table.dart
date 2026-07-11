import 'package:drift/drift.dart';

@DataClassName('ShopSettingsRow')
class ShopSettingsTable extends Table {
  @override
  String get tableName => 'shop_settings';

  @override
  List<String> get customConstraints => const ['CHECK(id = 1)'];

  IntColumn get id => integer().autoIncrement()();

  TextColumn get shopName =>
      text().customConstraint('NOT NULL CHECK(length(trim(shop_name)) > 0)')();

  TextColumn get shopSubtitle => text().nullable()();

  TextColumn get phoneNumber => text().nullable()();

  TextColumn get address => text().nullable()();

  TextColumn get logoPath => text().nullable()();

  TextColumn get repairCodePrefix => text().customConstraint(
    'NOT NULL CHECK(length(repair_code_prefix) BETWEEN 2 AND 10)',
  )();

  IntColumn get repairCodeNumberWidth => integer().customConstraint(
    'NOT NULL CHECK(repair_code_number_width BETWEEN 3 AND 8)',
  )();

  TextColumn get ticketFooter => text().nullable()();

  TextColumn get warrantyTerms => text().nullable()();

  TextColumn get defaultCustomerTicketPrinterId => text().nullable()();

  TextColumn get defaultDeviceLabelPrinterId => text().nullable()();

  TextColumn get publicShopId => text().nullable().unique()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();
}

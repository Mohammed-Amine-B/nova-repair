import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_code_sequence_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/repositories/drift_repair_repository.dart';
import 'package:nova_repair/features/repairs/domain/customer_price_decision.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_repair_input.dart';
import 'package:nova_repair/features/repairs/domain/repair_status.dart';
import 'package:nova_repair/features/settings/data/datasources/shop_settings_local_data_source.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  group('Repair persistence', () {
    late AppDatabase database;
    late RepairLocalDataSource localDataSource;
    late DriftRepairRepository repository;
    late DateTime currentTime;

    setUp(() {
      currentTime = DateTime.utc(2026, 1, 1, 9);
      database = AppDatabase(_inMemoryDatabase());
      localDataSource = RepairLocalDataSource(database);
      repository = DriftRepairRepository(
        database,
        localDataSource,
        RepairCodeSequenceLocalDataSource(database),
        ShopSettingsLocalDataSource(database),
        now: () => currentTime,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('creates a current-version database with repairs table', () async {
      await database.customSelect('SELECT 1').getSingle();

      final userVersion = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      final table = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'repairs'",
          )
          .getSingleOrNull();

      expect(database.schemaVersion, 7);
      expect(userVersion.read<int>('user_version'), 7);
      expect(table, isNotNull);
    });

    test('inserts and retrieves a repair through the repository', () async {
      final created = await repository.createRepair(
        CreateRepairInput(
          customerName: 'Amina',
          customerPhone: '0555000000',
          deviceType: 'Laptop',
          brand: 'Lenovo',
          model: 'T14',
          reportedProblem: 'Does not power on',
          priceAmount: 12500,
        ),
      );
      final byId = await repository.getRepairById(created.id!);
      final byCode = await repository.getRepairByCode('REP-0001');

      expect(byId, isNotNull);
      expect(byId!.id, created.id);
      expect(byId.repairCode, 'REP-0001');
      expect(byId.customerName, 'Amina');
      expect(byId.priceAmount, 12500);
      expect(byId.status, RepairStatus.received);
      expect(byId.customerPriceDecision, CustomerPriceDecision.notRequested);
      expect(byCode?.id, created.id);
    });

    test('persists nullable fields as null', () async {
      final created = await repository.createRepair(
        CreateRepairInput(reportedProblem: 'Does not power on'),
      );

      final repair = await repository.getRepairById(created.id!);

      expect(repair, isNotNull);
      expect(repair!.customerName, isNull);
      expect(repair.customerPhone, isNull);
      expect(repair.deviceType, isNull);
      expect(repair.brand, isNull);
      expect(repair.model, isNull);
      expect(repair.receivedAccessories, isNull);
      expect(repair.deviceAccessInfo, isNull);
      expect(repair.priceAmount, isNull);
      expect(repair.internalNotes, isNull);
      expect(repair.customerMessage, isNull);
      expect(repair.parentRepairId, isNull);
      expect(repair.readyAt, isNull);
      expect(repair.deliveredAt, isNull);
    });

    test('enforces unique repair codes', () async {
      await repository.createRepair(
        CreateRepairInput(reportedProblem: 'Does not power on'),
      );
      await repository.createRepair(
        CreateRepairInput(reportedProblem: 'Does not power on'),
      );

      final first = await repository.getRepairByCode('REP-0001');
      final second = await repository.getRepairByCode('REP-0002');

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(first?.id, isNot(second?.id));
    });

    test('persists integer DZD price values', () async {
      final created = await repository.createRepair(
        CreateRepairInput(
          reportedProblem: 'Does not power on',
          priceAmount: 2500,
        ),
      );

      final repair = await repository.getRepairById(created.id!);

      expect(repair?.priceAmount, 2500);
    });

    test('invalid stored enum values fail during mapping', () async {
      final now = DateTime.utc(2026, 1, 1, 9);
      await database
          .into(database.repairs)
          .insert(
            RepairsCompanion.insert(
              repairCode: 'REP-0008',
              reportedProblem: 'Does not charge',
              status: 'unknown_status',
              createdAt: now,
              updatedAt: now,
              receivedAt: now,
            ),
          );

      expect(
        () => repository.getRepairByCode('REP-0008'),
        throwsFormatException,
      );
    });
  });

  test('upgrades a version 1 database and creates repairs table', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'nova_repair_migration_test_',
    );
    addTearDown(() => tempDirectory.delete(recursive: true));

    final file = File('${tempDirectory.path}/migration.sqlite');
    final versionOneDatabase = sqlite3.sqlite3.open(file.path);
    versionOneDatabase.execute('PRAGMA user_version = 1');
    versionOneDatabase.close();

    final database = AppDatabase(_fileDatabase(file));
    addTearDown(database.close);

    final table = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'repairs'",
        )
        .getSingleOrNull();
    final userVersion = await database
        .customSelect('PRAGMA user_version')
        .getSingle();

    expect(table, isNotNull);
    expect(userVersion.read<int>('user_version'), 7);
  });
}

NativeDatabase _inMemoryDatabase() {
  return NativeDatabase.memory(
    setup: (database) {
      database.execute('PRAGMA foreign_keys = ON');
    },
  );
}

NativeDatabase _fileDatabase(File file) {
  return NativeDatabase(
    file,
    setup: (database) {
      database.execute('PRAGMA foreign_keys = ON');
    },
  );
}

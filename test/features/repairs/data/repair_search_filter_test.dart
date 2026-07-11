import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_code_sequence_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/repositories/drift_repair_repository.dart';
import 'package:nova_repair/features/repairs/domain/entities/repair_search_query.dart';
import 'package:nova_repair/features/repairs/domain/repair_status.dart';
import 'package:nova_repair/features/settings/data/datasources/shop_settings_local_data_source.dart';

void main() {
  late AppDatabase database;
  late DriftRepairRepository repository;

  setUp(() {
    database = AppDatabase(_inMemoryDatabase());
    repository = _repository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('text search', () {
    test('matches supported fields', () async {
      await insertRepair(
        database,
        repairCode: 'REP-0042',
        reportedProblem: 'No power',
      );
      await insertRepair(
        database,
        repairCode: 'REP-0043',
        customerName: 'Amina Haddad',
        reportedProblem: 'Display issue',
      );
      await insertRepair(
        database,
        repairCode: 'REP-0044',
        customerPhone: '0555123456',
        reportedProblem: 'Speaker issue',
      );
      await insertRepair(
        database,
        repairCode: 'REP-0045',
        deviceType: 'Laptop',
        reportedProblem: 'Keyboard issue',
      );
      await insertRepair(
        database,
        repairCode: 'REP-0046',
        brand: 'Samsung',
        reportedProblem: 'Charging issue',
      );
      await insertRepair(
        database,
        repairCode: 'REP-0047',
        model: 'ThinkPad T14',
        reportedProblem: 'Fan noise',
      );
      await insertRepair(
        database,
        repairCode: 'REP-0048',
        reportedProblem: 'Battery drains quickly',
      );

      expect(await codesForSearch(repository, '0042'), ['REP-0042']);
      expect(await codesForSearch(repository, 'amina'), ['REP-0043']);
      expect(await codesForSearch(repository, '0555'), ['REP-0044']);
      expect(await codesForSearch(repository, 'laptop'), ['REP-0045']);
      expect(await codesForSearch(repository, 'samsung'), ['REP-0046']);
      expect(await codesForSearch(repository, 't14'), ['REP-0047']);
      expect(await codesForSearch(repository, 'battery'), ['REP-0048']);
    });

    test('is case-insensitive and supports partial matching', () async {
      await insertRepair(
        database,
        repairCode: 'REP-0001',
        brand: 'Samsung',
        reportedProblem: 'Battery replacement',
      );

      expect(await codesForSearch(repository, 'SAMS'), ['REP-0001']);
      expect(await codesForSearch(repository, 'rep-000'), ['REP-0001']);
      expect(await codesForSearch(repository, 'place'), ['REP-0001']);
    });

    test('blank search behaves as no search filter', () async {
      await insertRepair(
        database,
        repairCode: 'REP-0001',
        reportedProblem: 'First',
      );
      await insertRepair(
        database,
        repairCode: 'REP-0002',
        reportedProblem: 'Second',
      );

      final repairs = await repository.searchRepairs(
        RepairSearchQuery(searchText: '   '),
      );

      expect(repairs.map((repair) => repair.repairCode), [
        'REP-0002',
        'REP-0001',
      ]);
    });

    test('does not search internal or sensitive fields', () async {
      await insertRepair(
        database,
        repairCode: 'REP-0001',
        reportedProblem: 'Visible problem',
        internalNotes: 'secret internal note',
        deviceAccessInfo: 'secret pin',
        customerMessage: 'secret customer message',
      );

      expect(await codesForSearch(repository, 'secret'), isEmpty);
      expect(await codesForSearch(repository, 'pin'), isEmpty);
    });

    test('treats percent and underscore as literal characters', () async {
      await insertRepair(
        database,
        repairCode: 'REP-0001',
        reportedProblem: 'Battery 100% health',
      );
      await insertRepair(
        database,
        repairCode: 'REP-0002',
        reportedProblem: 'Battery 1000 health',
      );
      await insertRepair(
        database,
        repairCode: 'REP-0003',
        reportedProblem: 'Model A_1 issue',
      );
      await insertRepair(
        database,
        repairCode: 'REP-0004',
        reportedProblem: 'Model AX1 issue',
      );

      expect(await codesForSearch(repository, '100%'), ['REP-0001']);
      expect(await codesForSearch(repository, 'A_1'), ['REP-0003']);
    });
  });

  group('status and lifecycle filters', () {
    test('one status, multiple statuses, and empty status set work', () async {
      await insertStatusSet(database);

      final repairing = await repository.searchRepairs(
        RepairSearchQuery(statuses: {RepairStatus.repairing}),
      );
      final activePair = await repository.searchRepairs(
        RepairSearchQuery(
          statuses: {RepairStatus.received, RepairStatus.diagnosing},
        ),
      );
      final noStatusFilter = await repository.searchRepairs(
        RepairSearchQuery(statuses: const {}),
      );

      expect(repairing.map((repair) => repair.status), [
        RepairStatus.repairing,
      ]);
      expect(activePair.map((repair) => repair.status).toSet(), {
        RepairStatus.received,
        RepairStatus.diagnosing,
      });
      expect(noStatusFilter, hasLength(8));
    });

    test('lifecycle scopes return expected statuses', () async {
      await insertStatusSet(database);

      final all = await repository.searchRepairs(
        RepairSearchQuery(lifecycleScope: RepairLifecycleScope.all),
      );
      final active = await repository.searchRepairs(
        RepairSearchQuery(lifecycleScope: RepairLifecycleScope.active),
      );
      final finalized = await repository.searchRepairs(
        RepairSearchQuery(lifecycleScope: RepairLifecycleScope.finalized),
      );

      expect(all, hasLength(8));
      expect(active.map((repair) => repair.status).toSet(), {
        RepairStatus.received,
        RepairStatus.diagnosing,
        RepairStatus.waitingForCustomerApproval,
        RepairStatus.waitingForPart,
        RepairStatus.repairing,
        RepairStatus.readyForPickup,
      });
      expect(finalized.map((repair) => repair.status).toSet(), {
        RepairStatus.delivered,
        RepairStatus.cancelled,
      });
    });

    test('scope and statuses combine by intersection', () async {
      await insertStatusSet(database);

      final activeRepairingOnly = await repository.searchRepairs(
        RepairSearchQuery(
          lifecycleScope: RepairLifecycleScope.active,
          statuses: {RepairStatus.repairing, RepairStatus.delivered},
        ),
      );
      final emptyIntersection = await repository.searchRepairs(
        RepairSearchQuery(
          lifecycleScope: RepairLifecycleScope.finalized,
          statuses: {RepairStatus.readyForPickup},
        ),
      );

      expect(activeRepairingOnly.map((repair) => repair.status), [
        RepairStatus.repairing,
      ]);
      expect(emptyIntersection, isEmpty);
    });
  });

  group('date range, sorting, and pagination', () {
    test('uses a half-open received date range', () async {
      await insertRepair(
        database,
        repairCode: 'REP-0001',
        reportedProblem: 'Before',
        receivedAt: DateTime.utc(2026, 1, 1),
      );
      await insertRepair(
        database,
        repairCode: 'REP-0002',
        reportedProblem: 'Lower bound',
        receivedAt: DateTime.utc(2026, 1, 2),
      );
      await insertRepair(
        database,
        repairCode: 'REP-0003',
        reportedProblem: 'Upper bound',
        receivedAt: DateTime.utc(2026, 1, 3),
      );

      final repairs = await repository.searchRepairs(
        RepairSearchQuery(
          receivedFrom: DateTime.utc(2026, 1, 2),
          receivedTo: DateTime.utc(2026, 1, 3),
        ),
      );

      expect(repairs.map((repair) => repair.repairCode), ['REP-0002']);
    });

    test('rejects invalid date range', () {
      expect(
        () => RepairSearchQuery(
          receivedFrom: DateTime.utc(2026, 1, 3),
          receivedTo: DateTime.utc(2026, 1, 3),
        ),
        throwsArgumentError,
      );
      expect(
        () => RepairSearchQuery(
          receivedFrom: DateTime.utc(2026, 1, 4),
          receivedTo: DateTime.utc(2026, 1, 3),
        ),
        throwsArgumentError,
      );
    });

    test(
      'sorts newest and oldest with deterministic ID tie-breakers',
      () async {
        await insertRepair(
          database,
          repairCode: 'REP-0001',
          reportedProblem: 'Oldest',
          receivedAt: DateTime.utc(2026, 1, 1),
        );
        await insertRepair(
          database,
          repairCode: 'REP-0002',
          reportedProblem: 'Same lower ID',
          receivedAt: DateTime.utc(2026, 1, 2),
        );
        await insertRepair(
          database,
          repairCode: 'REP-0003',
          reportedProblem: 'Same higher ID',
          receivedAt: DateTime.utc(2026, 1, 2),
        );

        final newest = await repository.searchRepairs(
          RepairSearchQuery(sort: RepairSearchSort.newestFirst),
        );
        final oldest = await repository.searchRepairs(
          RepairSearchQuery(sort: RepairSearchSort.oldestFirst),
        );

        expect(newest.map((repair) => repair.repairCode), [
          'REP-0003',
          'REP-0002',
          'REP-0001',
        ]);
        expect(oldest.map((repair) => repair.repairCode), [
          'REP-0001',
          'REP-0002',
          'REP-0003',
        ]);
      },
    );

    test('applies limit and offset and validates them', () async {
      for (var i = 1; i <= 5; i += 1) {
        await insertRepair(
          database,
          repairCode: 'REP-000$i',
          reportedProblem: 'Repair $i',
          receivedAt: DateTime.utc(2026, 1, i),
        );
      }

      final page = await repository.searchRepairs(
        RepairSearchQuery(limit: 2, offset: 1),
      );
      final zeroOffset = await repository.searchRepairs(
        RepairSearchQuery(limit: 1, offset: 0),
      );

      expect(page.map((repair) => repair.repairCode), ['REP-0004', 'REP-0003']);
      expect(zeroOffset.map((repair) => repair.repairCode), ['REP-0005']);
      expect(() => RepairSearchQuery(limit: 0), throwsArgumentError);
      expect(() => RepairSearchQuery(limit: -1), throwsArgumentError);
      expect(() => RepairSearchQuery(offset: -1), throwsArgumentError);
    });
  });

  test(
    'combined query uses search, scope, date, sort, limit, and offset',
    () async {
      await insertRepair(
        database,
        repairCode: 'REP-0001',
        customerPhone: '0555000000',
        reportedProblem: 'Battery issue',
        status: RepairStatus.repairing,
        receivedAt: DateTime.utc(2026, 1, 1),
      );
      await insertRepair(
        database,
        repairCode: 'REP-0002',
        customerPhone: '0555000000',
        reportedProblem: 'Battery issue',
        status: RepairStatus.repairing,
        receivedAt: DateTime.utc(2026, 1, 2),
      );
      await insertRepair(
        database,
        repairCode: 'REP-0003',
        customerPhone: '0555000000',
        reportedProblem: 'Battery issue',
        status: RepairStatus.delivered,
        receivedAt: DateTime.utc(2026, 1, 3),
      );
      await insertRepair(
        database,
        repairCode: 'REP-0004',
        customerPhone: '0555000000',
        reportedProblem: 'Screen issue',
        status: RepairStatus.repairing,
        receivedAt: DateTime.utc(2026, 1, 4),
      );

      final repairs = await repository.searchRepairs(
        RepairSearchQuery(
          searchText: 'battery',
          lifecycleScope: RepairLifecycleScope.active,
          receivedFrom: DateTime.utc(2026, 1, 1),
          receivedTo: DateTime.utc(2026, 1, 3),
          sort: RepairSearchSort.oldestFirst,
          limit: 1,
          offset: 1,
        ),
      );

      expect(repairs.map((repair) => repair.repairCode), ['REP-0002']);
    },
  );
}

Future<List<String>> codesForSearch(
  DriftRepairRepository repository,
  String searchText,
) async {
  final repairs = await repository.searchRepairs(
    RepairSearchQuery(searchText: searchText),
  );
  return repairs.map((repair) => repair.repairCode).toList();
}

Future<void> insertStatusSet(AppDatabase database) async {
  var index = 1;
  for (final status in RepairStatus.values) {
    await insertRepair(
      database,
      repairCode: 'REP-000$index',
      reportedProblem: status.name,
      status: status,
      receivedAt: DateTime.utc(2026, 1, index),
    );
    index += 1;
  }
}

Future<void> insertRepair(
  AppDatabase database, {
  required String repairCode,
  required String reportedProblem,
  RepairStatus status = RepairStatus.received,
  String? customerName,
  String? customerPhone,
  String? deviceType,
  String? brand,
  String? model,
  String? internalNotes,
  String? deviceAccessInfo,
  String? customerMessage,
  DateTime? receivedAt,
}) {
  final timestamp = receivedAt ?? DateTime.utc(2026, 1, 1, 9);
  return database
      .into(database.repairs)
      .insert(
        RepairsCompanion.insert(
          repairCode: repairCode,
          customerName: Value(customerName),
          customerPhone: Value(customerPhone),
          deviceType: Value(deviceType),
          brand: Value(brand),
          model: Value(model),
          reportedProblem: reportedProblem,
          deviceAccessInfo: Value(deviceAccessInfo),
          status: status.databaseValue,
          internalNotes: Value(internalNotes),
          customerMessage: Value(customerMessage),
          createdAt: timestamp,
          updatedAt: timestamp,
          receivedAt: timestamp,
        ),
      );
}

DriftRepairRepository _repository(AppDatabase database) {
  return DriftRepairRepository(
    database,
    RepairLocalDataSource(database),
    RepairCodeSequenceLocalDataSource(database),
    ShopSettingsLocalDataSource(database),
  );
}

NativeDatabase _inMemoryDatabase() {
  return NativeDatabase.memory(
    setup: (database) {
      database.execute('PRAGMA foreign_keys = ON');
    },
  );
}

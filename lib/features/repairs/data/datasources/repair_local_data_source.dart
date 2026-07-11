import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';
import '../../domain/entities/repair.dart';
import '../../domain/entities/repair_search_query.dart';
import '../../domain/repair_status.dart';

class RepairLocalDataSource {
  const RepairLocalDataSource(this._database);

  final AppDatabase _database;

  Future<int> insertRepair(Repair repair) {
    return _database
        .into(_database.repairs)
        .insert(
          RepairsCompanion.insert(
            repairCode: repair.repairCode,
            customerName: Value(repair.customerName),
            customerPhone: Value(repair.customerPhone),
            deviceType: Value(repair.deviceType),
            brand: Value(repair.brand),
            model: Value(repair.model),
            reportedProblem: repair.reportedProblem,
            receivedAccessories: Value(repair.receivedAccessories),
            deviceAccessInfo: Value(repair.deviceAccessInfo),
            status: repair.status.databaseValue,
            priceAmount: Value(repair.priceAmount),
            customerPriceDecision: Value(
              repair.customerPriceDecision.databaseValue,
            ),
            internalNotes: Value(repair.internalNotes),
            customerMessage: Value(repair.customerMessage),
            parentRepairId: Value(repair.parentRepairId),
            trackingToken: Value(repair.trackingToken),
            createdAt: repair.createdAt.toUtc(),
            updatedAt: repair.updatedAt.toUtc(),
            receivedAt: repair.receivedAt.toUtc(),
            readyAt: Value(repair.readyAt?.toUtc()),
            deliveredAt: Value(repair.deliveredAt?.toUtc()),
          ),
        );
  }

  Future<RepairRow?> getRepairById(int id) {
    return (_database.select(
      _database.repairs,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
  }

  Future<RepairRow?> getRepairByCode(String repairCode) {
    return (_database.select(
      _database.repairs,
    )..where((row) => row.repairCode.equals(repairCode))).getSingleOrNull();
  }

  Future<List<RepairRow>> getRecentRepairs({required int limit}) {
    _validatePagination(limit: limit);

    return (_database.select(_database.repairs)
          ..orderBy([
            (row) => OrderingTerm(
              expression: row.receivedAt,
              mode: OrderingMode.desc,
            ),
            (row) => OrderingTerm(expression: row.id, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .get();
  }

  Future<int> getRepairCount() async {
    final count = _database.repairs.id.count();
    final row = await (_database.selectOnly(
      _database.repairs,
    )..addColumns([count])).getSingle();

    return row.read(count)!;
  }

  Future<DateTime?> getLatestRepairUpdatedAt() async {
    final latestUpdatedAt = _database.repairs.updatedAt.max();
    final row = await (_database.selectOnly(
      _database.repairs,
    )..addColumns([latestUpdatedAt])).getSingle();

    return row.read(latestUpdatedAt)?.toUtc();
  }

  Future<List<RepairRow>> getReadyForPickupRepairs({
    required int limit,
    required int offset,
  }) {
    _validatePagination(limit: limit, offset: offset);

    return (_database.select(_database.repairs)
          ..where(
            (row) =>
                row.status.equals(RepairStatus.readyForPickup.databaseValue),
          )
          ..orderBy([
            (row) =>
                OrderingTerm(expression: row.readyAt, mode: OrderingMode.asc),
            (row) => OrderingTerm(expression: row.id, mode: OrderingMode.asc),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<List<RepairRow>> getReadyTooLongRepairs({
    required DateTime readyBefore,
    required int limit,
    required int offset,
  }) {
    _validatePagination(limit: limit, offset: offset);

    return (_database.select(_database.repairs)
          ..where(
            (row) =>
                row.status.equals(RepairStatus.readyForPickup.databaseValue) &
                (row.readyAt.isNull() |
                    row.readyAt.isSmallerThanValue(readyBefore.toUtc())),
          )
          ..orderBy([
            (row) =>
                OrderingTerm(expression: row.readyAt, mode: OrderingMode.asc),
            (row) => OrderingTerm(expression: row.id, mode: OrderingMode.asc),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<List<RepairRow>> getDelayedActiveRepairs({
    required DateTime receivedBefore,
    required List<String> activeStatusValues,
    required int limit,
    required int offset,
  }) {
    _validatePagination(limit: limit, offset: offset);

    return (_database.select(_database.repairs)
          ..where(
            (row) =>
                row.status.isIn(activeStatusValues) &
                row.receivedAt.isSmallerThanValue(receivedBefore.toUtc()),
          )
          ..orderBy([
            (row) => OrderingTerm(
              expression: row.receivedAt,
              mode: OrderingMode.asc,
            ),
            (row) => OrderingTerm(expression: row.id, mode: OrderingMode.asc),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<List<RepairRow>> getWarrantyReturnsForRepair(int repairId) {
    return (_database.select(_database.repairs)
          ..where((row) => row.parentRepairId.equals(repairId))
          ..orderBy([
            (row) => OrderingTerm(
              expression: row.receivedAt,
              mode: OrderingMode.desc,
            ),
            (row) => OrderingTerm(expression: row.id, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<List<RepairRow>> searchRepairs(RepairSearchQuery searchQuery) {
    final query = _database.select(_database.repairs);
    final effectiveStatuses = searchQuery.effectiveStatuses;

    if (searchQuery.searchText case final searchText?) {
      final pattern = '%${_escapeLike(searchText.toLowerCase())}%';
      query.where((row) {
        return row.repairCode.lower().like(pattern, escapeChar: r'\') |
            row.customerName.lower().like(pattern, escapeChar: r'\') |
            row.customerPhone.lower().like(pattern, escapeChar: r'\') |
            row.deviceType.lower().like(pattern, escapeChar: r'\') |
            row.brand.lower().like(pattern, escapeChar: r'\') |
            row.model.lower().like(pattern, escapeChar: r'\') |
            row.reportedProblem.lower().like(pattern, escapeChar: r'\');
      });
    }

    if (effectiveStatuses != null) {
      if (effectiveStatuses.isEmpty) {
        query.where((row) => const Constant(false));
      } else {
        query.where(
          (row) => row.status.isIn(
            effectiveStatuses
                .map((status) => status.databaseValue)
                .toList(growable: false),
          ),
        );
      }
    }

    if (searchQuery.receivedFrom case final receivedFrom?) {
      query.where(
        (row) => row.receivedAt.isBiggerOrEqualValue(receivedFrom.toUtc()),
      );
    }
    if (searchQuery.receivedTo case final receivedTo?) {
      query.where(
        (row) => row.receivedAt.isSmallerThanValue(receivedTo.toUtc()),
      );
    }

    query
      ..orderBy([
        (row) => OrderingTerm(
          expression: row.receivedAt,
          mode: searchQuery.sort == RepairSearchSort.newestFirst
              ? OrderingMode.desc
              : OrderingMode.asc,
        ),
        (row) => OrderingTerm(
          expression: row.id,
          mode: searchQuery.sort == RepairSearchSort.newestFirst
              ? OrderingMode.desc
              : OrderingMode.asc,
        ),
      ])
      ..limit(searchQuery.limit, offset: searchQuery.offset);

    return query.get();
  }

  Future<Map<String, int>> getStatusCountsByDatabaseValue() async {
    final status = _database.repairs.status;
    final count = status.count();
    final rows =
        await (_database.selectOnly(_database.repairs)
              ..addColumns([status, count])
              ..groupBy([status]))
            .get();

    return {for (final row in rows) row.read(status)!: row.read(count)!};
  }

  Future<int> getActiveRepairCount({
    required List<String> activeStatusValues,
  }) async {
    final count = _database.repairs.id.count();
    final row =
        await (_database.selectOnly(_database.repairs)
              ..addColumns([count])
              ..where(_database.repairs.status.isIn(activeStatusValues)))
            .getSingle();

    return row.read(count)!;
  }

  Future<int> getWaitingForCustomerApprovalCount() async {
    final count = _database.repairs.id.count();
    final row =
        await (_database.selectOnly(_database.repairs)
              ..addColumns([count])
              ..where(
                _database.repairs.status.equals(
                  RepairStatus.waitingForCustomerApproval.databaseValue,
                ),
              ))
            .getSingle();

    return row.read(count)!;
  }

  Future<int> getReadyTooLongCount({required DateTime readyBefore}) async {
    final count = _database.repairs.id.count();
    final row =
        await (_database.selectOnly(_database.repairs)
              ..addColumns([count])
              ..where(
                _database.repairs.status.equals(
                      RepairStatus.readyForPickup.databaseValue,
                    ) &
                    (_database.repairs.readyAt.isNull() |
                        _database.repairs.readyAt.isSmallerThanValue(
                          readyBefore.toUtc(),
                        )),
              ))
            .getSingle();

    return row.read(count)!;
  }

  Future<int> getDelayedActiveRepairCount({
    required DateTime receivedBefore,
    required List<String> activeStatusValues,
  }) async {
    final count = _database.repairs.id.count();
    final row =
        await (_database.selectOnly(_database.repairs)
              ..addColumns([count])
              ..where(
                _database.repairs.status.isIn(activeStatusValues) &
                    _database.repairs.receivedAt.isSmallerThanValue(
                      receivedBefore.toUtc(),
                    ),
              ))
            .getSingle();

    return row.read(count)!;
  }

  Future<int> updateRepairStatus({
    required int id,
    required String status,
    required DateTime updatedAt,
    required DateTime? readyAt,
    required bool updateReadyAt,
    required DateTime? deliveredAt,
    required bool updateDeliveredAt,
    required String? customerMessage,
    required bool updateCustomerMessage,
  }) {
    final companion = RepairsCompanion(
      status: Value(status),
      updatedAt: Value(updatedAt.toUtc()),
      readyAt: updateReadyAt ? Value(readyAt?.toUtc()) : const Value.absent(),
      deliveredAt: updateDeliveredAt
          ? Value(deliveredAt?.toUtc())
          : const Value.absent(),
      customerMessage: updateCustomerMessage
          ? Value(customerMessage)
          : const Value.absent(),
    );

    return (_database.update(
      _database.repairs,
    )..where((row) => row.id.equals(id))).write(companion);
  }

  Future<int> updateRepairDetails({
    required int id,
    required String? customerName,
    required String? customerPhone,
    required String deviceType,
    required String? brand,
    required String? model,
    required String reportedProblem,
    required String? receivedAccessories,
    required String? deviceAccessInfo,
    required String? internalNotes,
    required String? customerMessage,
    required DateTime updatedAt,
  }) {
    final companion = RepairsCompanion(
      customerName: Value(customerName),
      customerPhone: Value(customerPhone),
      deviceType: Value(deviceType),
      brand: Value(brand),
      model: Value(model),
      reportedProblem: Value(reportedProblem),
      receivedAccessories: Value(receivedAccessories),
      deviceAccessInfo: Value(deviceAccessInfo),
      internalNotes: Value(internalNotes),
      customerMessage: Value(customerMessage),
      updatedAt: Value(updatedAt.toUtc()),
    );

    return (_database.update(
      _database.repairs,
    )..where((row) => row.id.equals(id))).write(companion);
  }

  Future<int> updateRepairPriceState({
    required int id,
    required int? priceAmount,
    required String customerPriceDecision,
    required DateTime updatedAt,
  }) {
    final companion = RepairsCompanion(
      priceAmount: Value(priceAmount),
      customerPriceDecision: Value(customerPriceDecision),
      updatedAt: Value(updatedAt.toUtc()),
    );

    return (_database.update(
      _database.repairs,
    )..where((row) => row.id.equals(id))).write(companion);
  }

  String _escapeLike(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
  }

  void _validatePagination({required int limit, int offset = 0}) {
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'Must be positive.');
    }
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'Cannot be negative.');
    }
  }
}

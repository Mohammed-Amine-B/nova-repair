import '../../../../database/app_database.dart';
import '../../../settings/data/datasources/shop_settings_local_data_source.dart';
import '../../../settings/data/mappers/shop_settings_mapper.dart';
import '../../../settings/domain/entities/shop_settings.dart';
import '../../../online_tracking/data/datasources/tracking_sync_outbox_local_data_source.dart';
import '../../../online_tracking/infrastructure/tracking_token_generator.dart';
import '../../domain/customer_price_decision.dart';
import '../../domain/entities/change_repair_status_input.dart';
import '../../domain/entities/clear_repair_price_input.dart';
import '../../domain/entities/create_repair_input.dart';
import '../../domain/entities/create_warranty_return_input.dart';
import '../../domain/entities/propose_repair_price_input.dart';
import '../../domain/entities/record_customer_price_decision_input.dart';
import '../../domain/entities/repair.dart';
import '../../domain/entities/repair_attention_counts.dart';
import '../../domain/entities/repair_search_query.dart';
import '../../domain/entities/update_repair_input.dart';
import '../../domain/errors/repair_price_workflow_exception.dart';
import '../../domain/errors/repair_status_workflow_exception.dart';
import '../../domain/errors/warranty_return_workflow_exception.dart';
import '../../domain/repositories/repair_repository.dart';
import '../../domain/repair_status.dart';
import '../../domain/services/repair_code_generator.dart';
import '../../domain/services/repair_status_transition_policy.dart';
import '../datasources/repair_code_sequence_local_data_source.dart';
import '../datasources/repair_local_data_source.dart';
import '../mappers/repair_mapper.dart';

class DriftRepairRepository implements RepairRepository {
  DriftRepairRepository(
    this._database,
    this._localDataSource,
    this._sequenceLocalDataSource,
    this._shopSettingsLocalDataSource, {
    RepairCodeGenerator codeGenerator = const RepairCodeGenerator(),
    TrackingTokenGenerator? trackingTokenGenerator,
    TrackingSyncOutboxLocalDataSource? trackingSyncOutboxLocalDataSource,
    RepairStatusTransitionPolicy transitionPolicy =
        const RepairStatusTransitionPolicy(),
    DateTime Function()? now,
  }) : _codeGenerator = codeGenerator,
       _trackingTokenGenerator =
           trackingTokenGenerator ?? TrackingTokenGenerator(),
       _trackingSyncOutboxLocalDataSource =
           trackingSyncOutboxLocalDataSource ??
           TrackingSyncOutboxLocalDataSource(_database),
       _transitionPolicy = transitionPolicy,
       _now = now ?? DateTime.now;

  final AppDatabase _database;
  final RepairLocalDataSource _localDataSource;
  final RepairCodeSequenceLocalDataSource _sequenceLocalDataSource;
  final ShopSettingsLocalDataSource _shopSettingsLocalDataSource;
  final RepairCodeGenerator _codeGenerator;
  final TrackingTokenGenerator _trackingTokenGenerator;
  final TrackingSyncOutboxLocalDataSource _trackingSyncOutboxLocalDataSource;
  final RepairStatusTransitionPolicy _transitionPolicy;
  final DateTime Function() _now;

  @override
  Future<Repair> createRepair(CreateRepairInput input) {
    return _database.transaction(() => _createRepair(input));
  }

  @override
  Future<Repair> createWarrantyReturn(CreateWarrantyReturnInput input) {
    return _database.transaction(() async {
      final originalRow = await _localDataSource.getRepairById(
        input.originalRepairId,
      );
      if (originalRow == null) {
        throw WarrantyParentRepairNotFoundException(input.originalRepairId);
      }

      final originalRepair = originalRow.toDomain();
      if (originalRepair.status != RepairStatus.delivered) {
        throw RepairNotEligibleForWarrantyReturnException(
          repairId: originalRepair.id!,
          status: originalRepair.status,
        );
      }
      if (originalRepair.parentRepairId != null) {
        throw WarrantyReturnFromWarrantyReturnNotAllowedException(
          originalRepair.id!,
        );
      }

      return _createRepair(
        CreateRepairInput(
          customerName: originalRepair.customerName,
          customerPhone: originalRepair.customerPhone,
          deviceType: originalRepair.deviceType,
          brand: originalRepair.brand,
          model: originalRepair.model,
          reportedProblem: input.normalizedReportedProblem,
          receivedAccessories: input.receivedAccessories,
          deviceAccessInfo: input.deviceAccessInfo,
          internalNotes: input.internalNotes,
          customerMessage: input.customerMessage,
          receivedAt: input.receivedAt,
        ),
        parentRepairId: originalRepair.id,
      );
    });
  }

  @override
  Future<Repair> updateRepairDetails(UpdateRepairInput input) {
    return _database.transaction(() async {
      final currentRow = await _localDataSource.getRepairById(input.repairId);
      if (currentRow == null) {
        throw RepairNotFoundException(input.repairId);
      }

      final updatedCount = await _localDataSource.updateRepairDetails(
        id: input.repairId,
        customerName: input.normalizedText(input.customerName),
        customerPhone: input.normalizedText(input.customerPhone),
        deviceType: input.normalizedDeviceType,
        brand: input.normalizedText(input.brand),
        model: input.normalizedText(input.model),
        reportedProblem: input.normalizedReportedProblem,
        receivedAccessories: input.normalizedText(input.receivedAccessories),
        deviceAccessInfo: input.normalizedText(input.deviceAccessInfo),
        internalNotes: input.normalizedText(input.internalNotes),
        customerMessage: input.normalizedText(input.customerMessage),
        updatedAt: _now().toUtc(),
      );

      if (updatedCount != 1) {
        throw RepairNotFoundException(input.repairId);
      }

      await _enqueueTrackingRefresh(input.repairId);

      final updatedRow = await _localDataSource.getRepairById(input.repairId);
      if (updatedRow == null) {
        throw RepairNotFoundException(input.repairId);
      }

      return updatedRow.toDomain();
    });
  }

  Future<Repair> _createRepair(
    CreateRepairInput input, {
    int? parentRepairId,
  }) async {
    final settings = await _getOrCreateSettings();
    final sequence = await _advanceSequence();
    final repairCode = await _nextAvailableRepairCode(
      settings: settings,
      startingSequence: sequence,
    );

    if (parentRepairId != null &&
        await _localDataSource.getRepairById(parentRepairId) == null) {
      throw ArgumentError.value(
        parentRepairId,
        'parentRepairId',
        'Parent repair does not exist.',
      );
    }

    final now = _now().toUtc();
    final repair = Repair(
      repairCode: repairCode,
      customerName: input.normalizedText(input.customerName),
      customerPhone: input.normalizedText(input.customerPhone),
      deviceType: input.normalizedText(input.deviceType),
      brand: input.normalizedText(input.brand),
      model: input.normalizedText(input.model),
      reportedProblem: input.normalizedReportedProblem,
      receivedAccessories: input.normalizedText(input.receivedAccessories),
      deviceAccessInfo: input.normalizedText(input.deviceAccessInfo),
      status: RepairStatus.received,
      priceAmount: input.priceAmount,
      customerPriceDecision: CustomerPriceDecision.notRequested,
      internalNotes: input.normalizedText(input.internalNotes),
      customerMessage: input.normalizedText(input.customerMessage),
      parentRepairId: parentRepairId,
      trackingToken: _trackingTokenGenerator.generate(),
      createdAt: now,
      updatedAt: now,
      receivedAt: (input.receivedAt ?? now).toUtc(),
    );

    final id = await _localDataSource.insertRepair(repair);
    await _enqueueTrackingRefresh(id);
    final created = await _localDataSource.getRepairById(id);

    if (created == null) {
      throw StateError('Created repair could not be loaded.');
    }

    return created.toDomain();
  }

  @override
  Future<Repair> changeStatus(ChangeRepairStatusInput input) {
    return _database.transaction(() async {
      final currentRow = await _localDataSource.getRepairById(input.repairId);
      if (currentRow == null) {
        throw RepairNotFoundException(input.repairId);
      }

      final currentRepair = currentRow.toDomain();
      _transitionPolicy.validate(
        from: currentRepair.status,
        to: input.targetStatus,
      );

      final now = _now().toUtc();
      final enteringReadyForPickup =
          input.targetStatus == RepairStatus.readyForPickup;
      final enteringDelivered = input.targetStatus == RepairStatus.delivered;

      final updatedCount = await _localDataSource.updateRepairStatus(
        id: input.repairId,
        status: input.targetStatus.databaseValue,
        updatedAt: now,
        readyAt: enteringReadyForPickup ? now : currentRepair.readyAt,
        updateReadyAt: enteringReadyForPickup,
        deliveredAt: enteringDelivered ? now : currentRepair.deliveredAt,
        updateDeliveredAt: enteringDelivered,
        customerMessage: input.customerMessage.normalizedValue,
        updateCustomerMessage: input.customerMessage.shouldUpdate,
      );

      if (updatedCount != 1) {
        throw RepairNotFoundException(input.repairId);
      }

      await _enqueueTrackingRefresh(input.repairId);

      final updatedRow = await _localDataSource.getRepairById(input.repairId);
      if (updatedRow == null) {
        throw RepairNotFoundException(input.repairId);
      }

      return updatedRow.toDomain();
    });
  }

  @override
  Future<Repair> proposePrice(ProposeRepairPriceInput input) {
    return _database.transaction(() async {
      final currentRepair = await _loadRepairOrThrow(input.repairId);
      _validatePriceEditingStatus(
        currentRepair.status,
        operation: 'propose a price',
      );

      if (currentRepair.priceAmount == input.priceAmount &&
          currentRepair.customerPriceDecision ==
              CustomerPriceDecision.pending) {
        throw RepairPriceProposalAlreadyPendingException(input.repairId);
      }

      return _updatePriceState(
        repairId: input.repairId,
        priceAmount: input.priceAmount,
        decision: CustomerPriceDecision.pending,
      );
    });
  }

  @override
  Future<Repair> clearPrice(ClearRepairPriceInput input) {
    return _database.transaction(() async {
      final currentRepair = await _loadRepairOrThrow(input.repairId);
      _validatePriceEditingStatus(
        currentRepair.status,
        operation: 'clear a price',
      );

      return _updatePriceState(
        repairId: input.repairId,
        priceAmount: null,
        decision: CustomerPriceDecision.notRequested,
      );
    });
  }

  @override
  Future<Repair> recordCustomerPriceDecision(
    RecordCustomerPriceDecisionInput input,
  ) {
    return _database.transaction(() async {
      final currentRepair = await _loadRepairOrThrow(input.repairId);

      if (currentRepair.status != RepairStatus.waitingForCustomerApproval) {
        throw InvalidRepairPriceWorkflowStateException(
          status: currentRepair.status,
          operation: 'record a customer price decision',
        );
      }

      if (currentRepair.priceAmount == null) {
        throw RepairPriceProposalNotPresentException(input.repairId);
      }

      if (currentRepair.customerPriceDecision !=
          CustomerPriceDecision.pending) {
        throw InvalidCustomerPriceDecisionTransitionException(
          currentDecision: currentRepair.customerPriceDecision,
          targetDecision: input.decision,
        );
      }

      return _updatePriceState(
        repairId: input.repairId,
        priceAmount: currentRepair.priceAmount,
        decision: input.decision,
      );
    });
  }

  @override
  Future<Repair?> getRepairById(int id) async {
    final row = await _localDataSource.getRepairById(id);
    return row?.toDomain();
  }

  @override
  Future<Repair?> getRepairByCode(String repairCode) async {
    final row = await _localDataSource.getRepairByCode(repairCode.trim());
    return row?.toDomain();
  }

  @override
  Future<List<Repair>> getRecentRepairs({required int limit}) async {
    final rows = await _localDataSource.getRecentRepairs(limit: limit);
    return [for (final row in rows) row.toDomain()];
  }

  @override
  Future<int> getRepairCount() {
    return _localDataSource.getRepairCount();
  }

  @override
  Future<DateTime?> getLatestRepairUpdatedAt() {
    return _localDataSource.getLatestRepairUpdatedAt();
  }

  @override
  Future<List<Repair>> getWarrantyReturnsForRepair(int repairId) async {
    final rows = await _localDataSource.getWarrantyReturnsForRepair(repairId);
    return [for (final row in rows) row.toDomain()];
  }

  @override
  Future<List<Repair>> searchRepairs(RepairSearchQuery query) async {
    final rows = await _localDataSource.searchRepairs(query);
    return [for (final row in rows) row.toDomain()];
  }

  @override
  Future<List<Repair>> getReadyForPickupRepairs({
    required int limit,
    required int offset,
  }) async {
    final rows = await _localDataSource.getReadyForPickupRepairs(
      limit: limit,
      offset: offset,
    );
    return [for (final row in rows) row.toDomain()];
  }

  @override
  Future<List<Repair>> getReadyTooLongRepairs({
    required DateTime readyBefore,
    required int limit,
    required int offset,
  }) async {
    final rows = await _localDataSource.getReadyTooLongRepairs(
      readyBefore: readyBefore.toUtc(),
      limit: limit,
      offset: offset,
    );
    return [for (final row in rows) row.toDomain()];
  }

  @override
  Future<List<Repair>> getDelayedActiveRepairs({
    required DateTime receivedBefore,
    required int limit,
    required int offset,
  }) async {
    final rows = await _localDataSource.getDelayedActiveRepairs(
      receivedBefore: receivedBefore.toUtc(),
      activeStatusValues: _activeRepairStatusValues,
      limit: limit,
      offset: offset,
    );
    return [for (final row in rows) row.toDomain()];
  }

  @override
  Future<Map<RepairStatus, int>> getStatusCounts() async {
    final rawCounts = await _localDataSource.getStatusCountsByDatabaseValue();

    final counts = {for (final status in RepairStatus.values) status: 0};

    for (final entry in rawCounts.entries) {
      counts[RepairStatus.fromDatabaseValue(entry.key)] = entry.value;
    }

    return counts;
  }

  @override
  Future<int> getActiveRepairCount() {
    return _localDataSource.getActiveRepairCount(
      activeStatusValues: _activeRepairStatusValues,
    );
  }

  @override
  Future<RepairAttentionCounts> getAttentionCounts({
    required DateTime readyBefore,
    required DateTime delayedBefore,
  }) async {
    final waitingForCustomerApproval = await _localDataSource
        .getWaitingForCustomerApprovalCount();
    final readyTooLong = await _localDataSource.getReadyTooLongCount(
      readyBefore: readyBefore.toUtc(),
    );
    final delayedActive = await _localDataSource.getDelayedActiveRepairCount(
      receivedBefore: delayedBefore.toUtc(),
      activeStatusValues: _activeRepairStatusValues,
    );

    return RepairAttentionCounts(
      waitingForCustomerApproval: waitingForCustomerApproval,
      readyTooLong: readyTooLong,
      delayedActive: delayedActive,
    );
  }

  Future<Repair> _loadRepairOrThrow(int repairId) async {
    final row = await _localDataSource.getRepairById(repairId);
    if (row == null) {
      throw RepairNotFoundException(repairId);
    }

    return row.toDomain();
  }

  void _validatePriceEditingStatus(
    RepairStatus status, {
    required String operation,
  }) {
    if (!_priceEditableStatuses.contains(status)) {
      throw InvalidRepairPriceWorkflowStateException(
        status: status,
        operation: operation,
      );
    }
  }

  Future<Repair> _updatePriceState({
    required int repairId,
    required int? priceAmount,
    required CustomerPriceDecision decision,
  }) async {
    final updatedCount = await _localDataSource.updateRepairPriceState(
      id: repairId,
      priceAmount: priceAmount,
      customerPriceDecision: decision.databaseValue,
      updatedAt: _now().toUtc(),
    );

    if (updatedCount != 1) {
      throw RepairNotFoundException(repairId);
    }

    await _enqueueTrackingRefresh(repairId);

    final updatedRow = await _localDataSource.getRepairById(repairId);
    if (updatedRow == null) {
      throw RepairNotFoundException(repairId);
    }

    return updatedRow.toDomain();
  }

  Future<void> _enqueueTrackingRefresh(int repairId) {
    return _trackingSyncOutboxLocalDataSource.enqueueRepair(
      repairId: repairId,
      now: _now().toUtc(),
    );
  }

  Future<ShopSettings> _getOrCreateSettings() async {
    final row = await _shopSettingsLocalDataSource.getSettingsRow();
    if (row != null) {
      return row.toDomain();
    }

    final defaults = ShopSettings.defaults(_now().toUtc());
    await _shopSettingsLocalDataSource.upsertSettings(defaults);
    return defaults;
  }

  Future<int> _advanceSequence() async {
    final row = await _sequenceLocalDataSource.getSequenceRow();
    final lastUsed =
        row?.lastUsedSequence ?? await _maxExistingRepairSequence();
    final nextSequence = lastUsed + 1;

    await _sequenceLocalDataSource.saveLastUsedSequence(nextSequence);

    return nextSequence;
  }

  Future<int> _maxExistingRepairSequence() async {
    final rows = await _database.select(_database.repairs).get();
    var maxSequence = 0;

    for (final row in rows) {
      final sequence = _tryParseGeneratedSequence(row.repairCode);
      if (sequence != null && sequence > maxSequence) {
        maxSequence = sequence;
      }
    }

    return maxSequence;
  }

  int? _tryParseGeneratedSequence(String repairCode) {
    final separatorIndex = repairCode.lastIndexOf('-');
    if (separatorIndex <= 0 || separatorIndex == repairCode.length - 1) {
      return null;
    }

    final suffix = repairCode.substring(separatorIndex + 1);
    if (!RegExp(r'^[0-9]+$').hasMatch(suffix)) {
      return null;
    }

    return int.tryParse(suffix);
  }

  Future<String> _nextAvailableRepairCode({
    required ShopSettings settings,
    required int startingSequence,
  }) async {
    var sequence = startingSequence;

    while (true) {
      final repairCode = _codeGenerator.generate(
        prefix: settings.repairCodePrefix,
        numberWidth: settings.repairCodeNumberWidth,
        sequence: sequence,
      );

      if (await _localDataSource.getRepairByCode(repairCode) == null) {
        if (sequence != startingSequence) {
          await _sequenceLocalDataSource.saveLastUsedSequence(sequence);
        }
        return repairCode;
      }

      sequence += 1;
      await _sequenceLocalDataSource.saveLastUsedSequence(sequence);
    }
  }
}

final _activeRepairStatusValues = RepairSearchQuery.activeStatuses
    .map((status) => status.databaseValue)
    .toList(growable: false);

const _priceEditableStatuses = {
  RepairStatus.diagnosing,
  RepairStatus.waitingForCustomerApproval,
};

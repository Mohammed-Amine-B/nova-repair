import '../entities/change_repair_status_input.dart';
import '../entities/clear_repair_price_input.dart';
import '../entities/create_repair_input.dart';
import '../entities/create_warranty_return_input.dart';
import '../entities/propose_repair_price_input.dart';
import '../entities/record_customer_price_decision_input.dart';
import '../entities/repair.dart';
import '../entities/repair_attention_counts.dart';
import '../entities/repair_search_query.dart';
import '../entities/update_repair_input.dart';
import '../repair_status.dart';

abstract class RepairRepository {
  Future<Repair> createRepair(CreateRepairInput input);

  Future<Repair> createWarrantyReturn(CreateWarrantyReturnInput input);

  Future<Repair> updateRepairDetails(UpdateRepairInput input);

  Future<Repair> changeStatus(ChangeRepairStatusInput input);

  Future<Repair> proposePrice(ProposeRepairPriceInput input);

  Future<Repair> clearPrice(ClearRepairPriceInput input);

  Future<Repair> recordCustomerPriceDecision(
    RecordCustomerPriceDecisionInput input,
  );

  Future<Repair?> getRepairById(int id);

  Future<Repair?> getRepairByCode(String repairCode);

  Future<List<Repair>> getRecentRepairs({required int limit});

  Future<int> getRepairCount();

  Future<DateTime?> getLatestRepairUpdatedAt();

  Future<List<Repair>> getWarrantyReturnsForRepair(int repairId);

  Future<List<Repair>> searchRepairs(RepairSearchQuery query);

  Future<List<Repair>> getReadyForPickupRepairs({
    required int limit,
    required int offset,
  });

  Future<List<Repair>> getReadyTooLongRepairs({
    required DateTime readyBefore,
    required int limit,
    required int offset,
  });

  Future<List<Repair>> getDelayedActiveRepairs({
    required DateTime receivedBefore,
    required int limit,
    required int offset,
  });

  Future<Map<RepairStatus, int>> getStatusCounts();

  Future<int> getActiveRepairCount();

  Future<RepairAttentionCounts> getAttentionCounts({
    required DateTime readyBefore,
    required DateTime delayedBefore,
  });
}

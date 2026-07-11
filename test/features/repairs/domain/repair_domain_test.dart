import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/features/repairs/domain/customer_price_decision.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_repair_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/repair.dart';
import 'package:nova_repair/features/repairs/domain/repair_status.dart';
import 'package:nova_repair/features/repairs/domain/services/repair_code_generator.dart';

void main() {
  group('Repair', () {
    test('creates a valid repair', () {
      final now = DateTime.utc(2026, 1, 1, 9);

      final repair = Repair(
        repairCode: 'REP-0001',
        reportedProblem: 'Does not power on',
        createdAt: now,
        updatedAt: now,
        receivedAt: now,
      );

      expect(repair.repairCode, 'REP-0001');
      expect(repair.status, RepairStatus.received);
      expect(repair.customerPriceDecision, CustomerPriceDecision.notRequested);
    });

    test('rejects blank repair code', () {
      final now = DateTime.utc(2026, 1, 1, 9);

      expect(
        () => Repair(
          repairCode: '   ',
          reportedProblem: 'Does not power on',
          createdAt: now,
          updatedAt: now,
          receivedAt: now,
        ),
        throwsArgumentError,
      );
    });

    test('rejects blank reported problem', () {
      final now = DateTime.utc(2026, 1, 1, 9);

      expect(
        () => Repair(
          repairCode: 'REP-0001',
          reportedProblem: '',
          createdAt: now,
          updatedAt: now,
          receivedAt: now,
        ),
        throwsArgumentError,
      );
    });

    test('rejects negative price', () {
      final now = DateTime.utc(2026, 1, 1, 9);

      expect(
        () => Repair(
          repairCode: 'REP-0001',
          reportedProblem: 'Does not power on',
          priceAmount: -1,
          createdAt: now,
          updatedAt: now,
          receivedAt: now,
        ),
        throwsArgumentError,
      );
    });

    test('rejects warranty parent pointing to itself', () {
      final now = DateTime.utc(2026, 1, 1, 9);

      expect(
        () => Repair(
          id: 7,
          repairCode: 'REP-0007',
          reportedProblem: 'Returned for warranty',
          parentRepairId: 7,
          createdAt: now,
          updatedAt: now,
          receivedAt: now,
        ),
        throwsArgumentError,
      );
    });
  });

  group('RepairStatus', () {
    test('uses stable database values', () {
      expect(RepairStatus.received.databaseValue, 'received');
      expect(RepairStatus.diagnosing.databaseValue, 'diagnosing');
      expect(
        RepairStatus.waitingForCustomerApproval.databaseValue,
        'waiting_for_customer_approval',
      );
      expect(RepairStatus.waitingForPart.databaseValue, 'waiting_for_part');
      expect(RepairStatus.repairing.databaseValue, 'repairing');
      expect(RepairStatus.readyForPickup.databaseValue, 'ready_for_pickup');
      expect(RepairStatus.delivered.databaseValue, 'delivered');
      expect(RepairStatus.cancelled.databaseValue, 'cancelled');
    });

    test('deserializes stable database values', () {
      for (final status in RepairStatus.values) {
        expect(RepairStatus.fromDatabaseValue(status.databaseValue), status);
      }
    });

    test('rejects invalid stored values', () {
      expect(
        () => RepairStatus.fromDatabaseValue('ready'),
        throwsFormatException,
      );
    });
  });

  group('CustomerPriceDecision', () {
    test('uses stable database values', () {
      expect(CustomerPriceDecision.notRequested.databaseValue, 'not_requested');
      expect(CustomerPriceDecision.pending.databaseValue, 'pending');
      expect(CustomerPriceDecision.approved.databaseValue, 'approved');
      expect(CustomerPriceDecision.rejected.databaseValue, 'rejected');
    });

    test('deserializes stable database values', () {
      for (final decision in CustomerPriceDecision.values) {
        expect(
          CustomerPriceDecision.fromDatabaseValue(decision.databaseValue),
          decision,
        );
      }
    });

    test('rejects invalid stored values', () {
      expect(
        () => CustomerPriceDecision.fromDatabaseValue('accepted'),
        throwsFormatException,
      );
    });
  });

  group('CreateRepairInput', () {
    test('rejects blank reported problem', () {
      expect(
        () => CreateRepairInput(reportedProblem: '   '),
        throwsArgumentError,
      );
    });

    test('rejects negative price', () {
      expect(
        () => CreateRepairInput(
          reportedProblem: 'Does not power on',
          priceAmount: -1,
        ),
        throwsArgumentError,
      );
    });

    test('normalizes optional text', () {
      final input = CreateRepairInput(
        customerName: ' Amina ',
        reportedProblem: ' Does not power on ',
      );

      expect(input.normalizedText(input.customerName), 'Amina');
      expect(input.normalizedReportedProblem, 'Does not power on');
    });
  });

  group('RepairCodeGenerator', () {
    test('formats visible repair codes from settings and sequence', () {
      const generator = RepairCodeGenerator();

      expect(
        generator.generate(prefix: 'REP', numberWidth: 4, sequence: 1),
        'REP-0001',
      );
      expect(
        generator.generate(prefix: 'FIX', numberWidth: 5, sequence: 42),
        'FIX-00042',
      );
      expect(
        generator.generate(prefix: 'PC', numberWidth: 3, sequence: 123),
        'PC-123',
      );
    });

    test('does not truncate when sequence exceeds configured width', () {
      const generator = RepairCodeGenerator();

      expect(
        generator.generate(prefix: 'REP', numberWidth: 4, sequence: 10000),
        'REP-10000',
      );
    });
  });
}

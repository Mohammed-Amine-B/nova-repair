import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/features/repairs/domain/errors/repair_status_workflow_exception.dart';
import 'package:nova_repair/features/repairs/domain/repair_status.dart';
import 'package:nova_repair/features/repairs/domain/services/repair_status_transition_policy.dart';

void main() {
  const policy = RepairStatusTransitionPolicy();

  group('RepairStatusTransitionPolicy', () {
    test('allows every different status pair', () {
      for (final from in RepairStatus.values) {
        final allowedTargets = policy.allowedNextStatuses(from);

        expect(allowedTargets, isNot(contains(from)));
        expect(allowedTargets.length, RepairStatus.values.length - 1);

        for (final to in RepairStatus.values) {
          if (from == to) {
            continue;
          }

          expect(
            policy.canTransition(from: from, to: to),
            isTrue,
            reason: '${from.name} -> ${to.name}',
          );
          expect(
            () => policy.validate(from: from, to: to),
            returnsNormally,
            reason: '${from.name} -> ${to.name}',
          );
        }
      }
    });

    test('rejects same-status updates', () {
      for (final status in RepairStatus.values) {
        expect(
          policy.canTransition(from: status, to: status),
          isFalse,
          reason: status.name,
        );
        expect(
          () => policy.validate(from: status, to: status),
          throwsA(isA<InvalidRepairStatusTransitionException>()),
          reason: status.name,
        );
      }
    });

    test('covers flexible workflow examples', () {
      expect(
        policy.canTransition(
          from: RepairStatus.received,
          to: RepairStatus.repairing,
        ),
        isTrue,
      );
      expect(
        policy.canTransition(
          from: RepairStatus.received,
          to: RepairStatus.waitingForPart,
        ),
        isTrue,
      );
      expect(
        policy.canTransition(
          from: RepairStatus.repairing,
          to: RepairStatus.diagnosing,
        ),
        isTrue,
      );
      expect(
        policy.canTransition(
          from: RepairStatus.readyForPickup,
          to: RepairStatus.repairing,
        ),
        isTrue,
      );
      expect(
        policy.canTransition(
          from: RepairStatus.delivered,
          to: RepairStatus.repairing,
        ),
        isTrue,
      );
      expect(
        policy.canTransition(
          from: RepairStatus.cancelled,
          to: RepairStatus.diagnosing,
        ),
        isTrue,
      );
      expect(
        policy.canTransition(
          from: RepairStatus.waitingForPart,
          to: RepairStatus.readyForPickup,
        ),
        isTrue,
      );
    });
  });
}

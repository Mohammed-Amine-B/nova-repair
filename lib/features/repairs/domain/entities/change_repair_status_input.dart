import '../repair_status.dart';

class ChangeRepairStatusInput {
  const ChangeRepairStatusInput({
    required this.repairId,
    required this.targetStatus,
    this.customerMessage = const OptionalCustomerMessage.unchanged(),
  });

  final int repairId;
  final RepairStatus targetStatus;
  final OptionalCustomerMessage customerMessage;
}

class OptionalCustomerMessage {
  const OptionalCustomerMessage.unchanged()
    : value = null,
      shouldUpdate = false;

  const OptionalCustomerMessage.replace(this.value) : shouldUpdate = true;

  final String? value;
  final bool shouldUpdate;

  String? get normalizedValue {
    final currentValue = value;
    if (currentValue == null) {
      return null;
    }

    final trimmed = currentValue.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

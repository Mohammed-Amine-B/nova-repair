class RepairCodeGenerator {
  const RepairCodeGenerator();

  String generate({
    required String prefix,
    required int numberWidth,
    required int sequence,
  }) {
    if (sequence < 1) {
      throw ArgumentError.value(sequence, 'sequence', 'Must be positive.');
    }

    final paddedSequence = sequence.toString().padLeft(numberWidth, '0');
    return '$prefix-$paddedSequence';
  }
}

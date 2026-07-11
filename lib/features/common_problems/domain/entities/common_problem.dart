class CommonProblem {
  CommonProblem({
    this.id,
    required this.title,
    required this.usageCount,
    required this.createdAt,
    required this.updatedAt,
  }) {
    if (title.trim().isEmpty) {
      throw const FormatException('Common problem title cannot be blank.');
    }
    if (usageCount < 0) {
      throw const FormatException(
        'Common problem usage count cannot be negative.',
      );
    }
  }

  final int? id;
  final String title;
  final int usageCount;
  final DateTime createdAt;
  final DateTime updatedAt;
}

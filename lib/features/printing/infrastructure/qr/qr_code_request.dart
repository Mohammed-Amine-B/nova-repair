class QrCodeRequest {
  QrCodeRequest({required String payload, required this.size})
    : payload = payload.trim() {
    if (this.payload.isEmpty) {
      throw ArgumentError.value(payload, 'payload', 'Cannot be blank.');
    }
    if (size <= 0) {
      throw ArgumentError.value(size, 'size', 'Must be positive.');
    }
  }

  final String payload;
  final int size;
}

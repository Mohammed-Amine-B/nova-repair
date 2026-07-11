class DeviceDisplayNameFormatter {
  const DeviceDisplayNameFormatter();

  String format({String? brand, String? model, String? deviceType}) {
    final normalizedBrand = _normalize(brand);
    final normalizedModel = _normalize(model);
    final normalizedDeviceType = _normalize(deviceType);

    if (normalizedBrand != null && normalizedModel != null) {
      return _combineWithoutDuplicatePrefix(normalizedBrand, normalizedModel);
    }
    if (normalizedBrand != null && normalizedDeviceType != null) {
      return _combineWithoutDuplicatePrefix(
        normalizedBrand,
        normalizedDeviceType,
      );
    }
    if (normalizedModel != null) {
      return normalizedModel;
    }
    if (normalizedDeviceType != null) {
      return normalizedDeviceType;
    }

    return 'Device';
  }

  String _combineWithoutDuplicatePrefix(String prefix, String value) {
    final prefixLower = prefix.toLowerCase();
    final valueLower = value.toLowerCase();

    if (valueLower == prefixLower || valueLower.startsWith('$prefixLower ')) {
      return value;
    }

    return '$prefix $value';
  }

  String? _normalize(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

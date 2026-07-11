class CommonProblemTitleNormalizer {
  const CommonProblemTitleNormalizer();

  String normalizeTitle(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String normalizeForDuplicateCheck(String value) {
    return normalizeTitle(value).toLowerCase();
  }
}

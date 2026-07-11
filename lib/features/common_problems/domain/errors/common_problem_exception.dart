sealed class CommonProblemException implements Exception {
  const CommonProblemException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InvalidCommonProblemTitleException extends CommonProblemException {
  const InvalidCommonProblemTitleException()
    : super('Common problem title is required.');
}

class DuplicateCommonProblemTitleException extends CommonProblemException {
  const DuplicateCommonProblemTitleException(this.title)
    : super('A common problem with this title already exists.');

  final String title;
}

class CommonProblemNotFoundException extends CommonProblemException {
  const CommonProblemNotFoundException(this.id)
    : super('Common problem was not found.');

  final int id;
}

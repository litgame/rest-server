enum ErrorType { validation, exists, anotherGame, access, state, notFound }

extension ToErrorType on String {
  ErrorType toError() {
    switch (this) {
      case 'validation':
        return ErrorType.validation;
      case 'already_exists':
        return ErrorType.exists;
      case 'another_game':
        return ErrorType.anotherGame;
      case 'access':
        return ErrorType.access;
      case 'state':
        return ErrorType.state;
      case 'not_found':
        return ErrorType.notFound;
    }
    throw 'String is not of any supported type';
  }
}

extension FromErrorType on ErrorType {
  String toErrorString() {
    switch (this) {
      case ErrorType.validation:
        return 'validation';
      case ErrorType.exists:
        return 'already_exists';
      case ErrorType.anotherGame:
        return 'another_game';
      case ErrorType.access:
        return 'access';
      case ErrorType.state:
        return 'state';
      case ErrorType.notFound:
        return 'not_found';
    }
  }
}

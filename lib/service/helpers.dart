import 'dart:convert';

import 'package:shelf/shelf.dart';

import 'error.dart';

const Map<String, String> jsonHttpHeader = {'Content-Type': 'application/json'};

extension ToJson on Map {
  String toJson() => jsonEncode(this);
}

class SuccessResponse extends Response {
  SuccessResponse(Map data)
      : super(200, body: data.toJson(), headers: jsonHttpHeader);
}

class ErrorResponse extends Response {
  ErrorResponse(String error)
      : super.internalServerError(
            body: {'error': error, 'type': ErrorType.validation.toErrorString()}
                .toJson(),
            headers: jsonHttpHeader);
}

class ErrorNotFoundResponse extends Response {
  ErrorNotFoundResponse(String error)
      : super.internalServerError(
            body: {'error': error, 'type': ErrorType.notFound.toErrorString()}
                .toJson(),
            headers: jsonHttpHeader);
}

class ErrorStateResponse extends Response {
  ErrorStateResponse(String error)
      : super.internalServerError(
            body: {'error': error, 'type': ErrorType.state.toErrorString()}
                .toJson(),
            headers: jsonHttpHeader);
}

class ErrorExistingResponse extends Response {
  ErrorExistingResponse(String error)
      : super.internalServerError(
            body: {'error': error, 'type': ErrorType.exists.toErrorString()}
                .toJson(),
            headers: jsonHttpHeader);
}

class ErrorAnotherGameResponse extends Response {
  ErrorAnotherGameResponse(String error, String gameId)
      : super.internalServerError(
            body: {
              'error': error,
              'type': ErrorType.anotherGame.toErrorString(),
              'gameId': gameId
            }.toJson(),
            headers: jsonHttpHeader);
}

class ErrorAccessResponse extends Response {
  ErrorAccessResponse(String error)
      : super.internalServerError(
            body: {'error': error, 'type': ErrorType.access.toErrorString()}
                .toJson(),
            headers: jsonHttpHeader);
}

typedef BodyItemValidator = String? Function(
    dynamic value, Map<String, dynamic> allBody);

class JsonBodyValidator {
  JsonBodyValidator(this.request, this._rules);

  final Request request;
  final Map<String, BodyItemValidator?> _rules;

  Map<String, dynamic>? _body;

  Map<String, dynamic> get validatedJson {
    if (_body == null) throw 'Request did not checked!';
    return _body as Map<String, dynamic>;
  }

  Future<Response?> validate() async {
    var jsonData;
    try {
      jsonData =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (decodeError) {
      return ErrorResponse('Error decoding JSON: ' + decodeError.toString());
    }
    for (var item in _rules.entries) {
      final value = jsonData[item.key];
      if (value == null) {
        return ErrorResponse('Field ${item.key} does not exists');
      }

      final checkFunction = item.value;
      if (checkFunction != null) {
        final error = checkFunction(value, jsonData);
        if (error != null) {
          return ErrorResponse('Field ${item.key} validation error: $error');
        }
      }
    }

    _body = jsonData;
    return null;
  }
}

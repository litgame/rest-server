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

abstract class CoreValidator {
  CoreValidator(this.request, this.rules);

  final Request request;
  final Map<String, BodyItemValidator?> rules;

  Map<String, dynamic>? data;

  Map<String, dynamic> get validated {
    if (data == null) throw 'Request did not checked!';
    return data as Map<String, dynamic>;
  }

  Future<Response?> validate();
}

class JsonBodyValidator extends CoreValidator {
  JsonBodyValidator(Request request, Map<String, BodyItemValidator?> rules)
      : super(request, rules);

  Future<Response?> validate() async {
    var jsonData;
    try {
      jsonData =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (decodeError) {
      return ErrorResponse('Error decoding JSON: ' + decodeError.toString());
    }
    for (var item in rules.entries) {
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

    data = jsonData;
    return null;
  }
}

class GetValidator extends CoreValidator {
  GetValidator(Request request, Map<String, BodyItemValidator?> rules)
      : super(request, rules);

  @override
  Future<Response?> validate() async {
    var query = request.url.queryParameters;
    for (var item in rules.entries) {
      final value = query[item.key];
      if (value == null) {
        return ErrorResponse('Field ${item.key} does not exists');
      }

      final checkFunction = item.value;
      if (checkFunction != null) {
        final error = checkFunction(value, query);
        if (error != null) {
          return ErrorResponse('Field ${item.key} validation error: $error');
        }
      }
    }

    data = query;
    return null;
  }
}

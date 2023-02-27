part of openapi_client_delegates;

/// This class is used for printing request and responses
/// Example:
///```dart
///ApiClient apiClient = ApiClient(
///   basePath: 'Config.url',
///   apiClientDelegate: PrintingClientDelegate(
///     onResponse: (String requestLog) => print(requestLog),
///     logLevels: {
///       'a/call/you/dont/want/to/log/like/file/upload': LogLevel.none,
///       'a/frequent/call': LogLevel.url,
///     },
///   ),
/// );
///```
class PrintingClientDelegate extends DioClientDelegate {
  final JsonEncoder _encoder = new JsonEncoder.withIndent('  ');
  final Function(String) onResponse;
  final Map<String, LogLevel> logLevels;
  final LogLevel defaultLogLevel;

  PrintingClientDelegate({
    Dio? client,
    required this.onResponse,
    this.logLevels = const {},
    this.defaultLogLevel = LogLevel.body,
  }) : super(client);

  @override
  Future<ApiResponse> invokeAPI(
    String basePath,
    String path,
    Iterable<QueryParam> queryParams,
    Object? body,
    Options options, {
    bool passErrorsAsApiResponses = false,
  }) async {
    final logLevel = logLevels[path] ?? defaultLogLevel;
    StringBuffer sb = new StringBuffer();

    if (logLevel.index >= LogLevel.url.index) {
      sb.write('REQUEST: ${options.method} $basePath$path ');
      onResponse(sb.toString());
    }

    if (logLevel.index >= LogLevel.body.index) {
      sb.writeln('\n${options.headers}');
      if (queryParams.isNotEmpty) {
        sb.writeln(queryParams.fold('QUERY PARAMS:', (s, element) => '$s {${element.name}:${element.value}}'));
      }
      sb.writeln(_encoder.convert(body));
      sb.writeln();
    }

    final apiResponse = await super.invokeAPI(
      basePath,
      path,
      queryParams,
      body,
      options,
    );

    if (logLevel.index >= LogLevel.url.index) {
      sb.write('RESPONSE: ${apiResponse.statusCode}');
    }

    if (logLevel.index >= LogLevel.body.index) {
      sb.writeln('\n${apiResponse.headers}');
      apiResponse.body = _copyResponse(apiResponse.body, (response) {
        sb.writeln('BODY:');
        sb.write(response);
        onResponse(sb.toString());
        sb.clear();
      });
    } else if (logLevel.index >= LogLevel.url.index) {
      onResponse(sb.toString());
      sb.clear();
    }

    return apiResponse;
  }

  Stream<List<int>> _copyResponse(
    Stream<List<int>>? stream,
    Function(String) onResponse,
  ) {
    StringBuffer res = new StringBuffer();
    final controller = StreamController<List<int>>();

    stream?.listen(
      (List<int> event) {
        res.write(utf8.decode(event));
        controller.sink.add(event);
      },
      onDone: () {
        var encoded = res.toString();
        try {
          encoded = _encoder.convert(jsonDecode(encoded));
        } catch (_) {
        } finally {
          onResponse(encoded);
          controller.close();
        }
      },
      onError: (e, s) => controller.addError(e, s),
    );

    return controller.stream;
  }
}

enum LogLevel { none, url, body }

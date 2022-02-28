part of openapi_client_delegates;

/// This class is used for printing request and responses
/// Example:
///
/// ApiClient apiClient = ApiClient(
//         basePath: Config.url,
//         apiClientDelegate: PrintingClientDelegate(
//             onResponse: (String requestLog)=>log(requestLog),
//         ),
//       );
class PrintingClientDelegate extends DioClientDelegate {
  final JsonEncoder _encoder = new JsonEncoder.withIndent('  ');
  final Function(String) onResponse;

  PrintingClientDelegate({required this.onResponse});

  @override
  Future<ApiResponse> invokeAPI(
    String basePath,
    String path,
    Iterable<QueryParam> queryParams,
    Object? body,
    Options options, {
    bool passErrorsAsApiResponses = false,
  }) async {
    StringBuffer sb = new StringBuffer();
    sb.writeln('REQUEST:');
    sb.writeln('${options.method} $basePath$path');
    sb.writeln('${options.headers}');
    if (queryParams.isNotEmpty) {
      sb.writeln(queryParams.fold('QUERY PARAMS:',
          (s, element) => '$s {${element.name}:${element.value}}'));
    }
    sb.writeln(_encoder.convert(body));

    final apiResponse = await super.invokeAPI(
      basePath,
      path,
      queryParams,
      body,
      options,
    );

    sb.writeln('\nRESPONSE: ${apiResponse.statusCode}');
    sb.writeln('${apiResponse.headers}');
    apiResponse.body = _copyResponse(apiResponse.body, (response) {
      sb.writeln('BODY:');
      sb.write(response);
      onResponse(sb.toString());
      sb.clear();
    });
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

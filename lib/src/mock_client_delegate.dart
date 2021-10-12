part of openapi_client_delegates;

/// This class is used for mocking responses instead of api request
/// Example:
///
/// const Map<String, String> responseMap = {
//   '/auth/login': """{
//   "success": true,
//   "message": "SUCCESS",
//   "data": {
//     "accessToken": "908d1be3-a2ce-46b2-9548-edc435b736e9"
//   }
// }""",
//   '/some-other-endpoint': """some-other-response""",
// };
//
// ApiClient apiClient = ApiClient(
//         basePath: Config.url,
//         apiClientDelegate: MockClientDelegate(
//             responseMap: responseMap
//             onResponse: (String requestLog)=>log(requestLog),
//         ),
//       );
class MockClientDelegate extends DioClientDelegate {
  final Map<String, String> responseMap;
  final Function(String) onResponse;

  MockClientDelegate({required this.responseMap, required this.onResponse});

  @override
  Future<ApiResponse> invokeAPI(
    String basePath,
    String path,
    Iterable<QueryParam> queryParams,
    Object? body,
    Options options, {
    bool passErrorsAsApiResponses = false,
  }) async {
    final responseString = responseMap[path] ?? '{}';
    onResponse('Mock Response:\n$path\n$responseString');
    final responseStream = responseToStream(responseString);
    return ApiResponse(200, {}, responseStream);
  }

  Stream<List<int>> responseToStream(String response) async* {
    for (final s in response.split('')) {
      yield utf8.encode(s);
    }
  }
}

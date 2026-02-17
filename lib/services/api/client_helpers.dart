import 'dart:developer' as dev;

import 'package:graphql_flutter/graphql_flutter.dart' as gql;
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

abstract class ClientHelper<T, R> {

  Future<R> request(T params);

  bool get isValid => true;

  void dispose() {

  }

}

abstract class RestClientHelper extends ClientHelper<RestParams, http.Response> {

  Future<http.Response> get(String path, [Map<String, dynamic>? params]) {
    dev.log('[RestClientHelper] GET: path=$path, params=$params');
    return _handleResponse(request(RestParams(method: RequestMethod.get, path: path, params: params)));
  }

  Future<http.Response> post(String path, dynamic body) {
    dev.log('[RestClientHelper] POST: path=$path, body=$body');
    return _handleResponse(request(RestParams(method: RequestMethod.post, path: path, body: body)));
  }

  Future<Response> _handleResponse(Future<Response> futureResponse) async {
    final response = await futureResponse;
    dev.log('[RestClientHelper] Response code: ${response.statusCode}');
    // dev.log('[RestClientHelper] Response: ${response.body}');
    dev.log('[RestClientHelper] Rate limit headers:');
    for (var headerEntry in response.headers.entries) {
      // dev.log('[RestClientHelper] ${headerEntry.key}: ${headerEntry.value}');
      if (headerEntry.key.startsWith('x-ratelimit-')) {
        dev.log('[RestClientHelper]\t${headerEntry.key}: ${headerEntry.value}');
      }
    }
    return response;
  }

}

class GraphQlClientHelper extends ClientHelper<gql.QueryOptions, gql.QueryResult> {

  final gql.GraphQLClient _client;

  GraphQlClientHelper(String baseUrl, Map<String, String> Function() headersProvider)
    : _client = gql.GraphQLClient(
        link: gql.Link.function((request, [forward]) {
          final customHeaders = headersProvider();
          dev.log('[GraphQlClientHelper] Request headers: ${customHeaders.length}');
          dev.log('[GraphQlClientHelper]\tUser-Agent: ${customHeaders['User-Agent']}');
          return forward!(
            request.updateContextEntry<gql.HttpLinkHeaders>(
              (headers) => gql.HttpLinkHeaders(
                headers: {
                  ...?headers?.headers,
                  ...customHeaders
                },
              ),
            )
          ).map((response) {
            final responseContext = response.context.entry<gql.HttpLinkResponseContext>();
            if (responseContext != null) {
              dev.log('[GraphQlClientHelper] Response code: ${responseContext.statusCode}');
            }
            // dev.log('[GraphQlClientHelper] Response: ${response.data}');
            return response;
          });
        }).concat(gql.HttpLink(baseUrl)),
        cache: gql.GraphQLCache(),
        defaultPolicies: gql.DefaultPolicies(
          query: gql.Policies(
            fetch: gql.FetchPolicy.networkOnly,
          )
        )
      );
  
  @override
  Future<gql.QueryResult<Object?>> request(gql.QueryOptions<Object?> params) async {
    final response = await _client.query(params);
    // dev.log('[GraphQlClientHelper] Response: ${response.data}');
    return response;
  }

  @override
  void dispose() {
    _client.resetStore();
  }

}

abstract class AuthClientHelper<T, R> extends ClientHelper<T, R>{

  Future<bool> fetchToken();

  Future<void> saveToken(String userId);

}

class RestParams {

  final RequestMethod method;
  final String path;
  final Map<String, dynamic>? params;
  final dynamic body;

  const RestParams({
    required this.method,
    required this.path,
    this.params,
    this.body
  });

}

enum RequestMethod {
  get,
  post,
}
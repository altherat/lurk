import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart' as gql;
import 'package:http/http.dart';

abstract class ClientHelper {

  bool get isValid => true;

  void dispose() {

  }

}

abstract class RestClientHelper extends ClientHelper {

  final String host;
  final Map<String, String> _headers;

  RestClientHelper(this.host, Map<String, String> headers)
    : _headers = Map.of(headers);

  @protected
  Future<Response> performGet(Uri uri, Map<String, String> headers);
  
  @protected
  Future<Response> performPost(Uri uri, Map<String, String> headers, dynamic body);

  Future<Response> get(String path, [Map<String, dynamic>? params]) {
    dev.log('[RestClientHelper] GET: ${Uri.https(host, path, params)}');
    return _debugPrintResponse(
      request(
        _headers,
        (headers) {
          _debugPrintRequestHeaders(headers);
          return performGet(Uri.https(host, path, params), headers);
        }
      )
    );
  }

  Future<Response> post(String path, dynamic body) {
    dev.log('[RestClientHelper] POST: ${Uri.https(host, path)}, body=$body');
    return _debugPrintResponse(
      request(
        _headers,
        (headers) {
          _debugPrintRequestHeaders(headers);
          return performPost(Uri.https(host, path), headers, body);
        }
      )
    );
  }

  @protected
  Future<Response> request(Map<String, String> headers, Future<Response> Function(Map<String, String> headers) request) => request(headers);

  void _debugPrintRequestHeaders(Map<String, String> headers) {
    dev.log('[RestClientHelper] Request headers: ${headers.length}');
    dev.log('[RestClientHelper]\tUser-Agent: ${headers['User-Agent']}');
  }

  Future<Response> _debugPrintResponse(Future<Response> futureResponse) async {
    final response = await futureResponse;
    dev.log('[RestClientHelper] Response code: ${response.statusCode}');
    // dev.log('[RestClientHelper] Response: ${response.body}');
    if (response.headers.keys.any((key) => key.startsWith('x-ratelimit-'))) {
      dev.log('[RestClientHelper] Rate limit headers:');
      for (var headerEntry in response.headers.entries) {
        // dev.log('[RestClientHelper] ${headerEntry.key}: ${headerEntry.value}');
        if (headerEntry.key.startsWith('x-ratelimit-')) {
          dev.log('[RestClientHelper]\t${headerEntry.key}: ${headerEntry.value}');
        }
      }
    }
    return response;
  }

}


class SimpleRestClientHelper extends RestClientHelper {

  static final Client _client = Client();
  
  @protected
  Client get client => _client;

  SimpleRestClientHelper(super.host, super.headers);
  
  @override
  Future<Response> performGet(Uri uri, Map<String, String> headers) => _client.get(uri, headers: headers);
  
  @override
  Future<Response> performPost(Uri uri, Map<String, String> headers, dynamic body) {
    dev.log('[SimpleRestClientHelper] performPost: uri=$uri, body=$body');
    return _client.post(uri, headers: headers, body: body);
  }

}

class GraphQlClientHelper extends ClientHelper {

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
  
  Future<gql.QueryResult<Object?>> query(gql.QueryOptions<Object?> params) async {
    final response = await _client.query(params);
    // dev.log('[GraphQlClientHelper] Response: ${response.data}');
    return response;
  }

  @override
  void dispose() {
    _client.resetStore();
  }

}

abstract interface class AuthClientHelper extends ClientHelper {

  Future<FetchTokenResult> fetchToken([Map<String, String>? credentials]);

  Future<void> saveToken(String userId);

}

sealed class FetchTokenResult {}

class FetchTokenSuccess extends FetchTokenResult {

  FetchTokenSuccess();

}

class FetchTokenError extends FetchTokenResult {

  final String? message;
  
  FetchTokenError([this.message]);

}
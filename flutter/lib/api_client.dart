import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

/// Errore del backend con il messaggio (già in italiano) pronto per l'utente.
class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Client HTTP verso il backend GuidaTour: aggiunge il token Supabase
/// dell'utente loggato (se presente) e traduce gli errori del backend.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  Uri _uri(String path, Map<String, String>? query) {
    final uri = Uri.parse('$backendUrl$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, ...query});
  }

  Map<String, String> get _headers {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, [Object? body]) =>
      _send('POST', path, body: body);

  Future<dynamic> patch(String path, [Object? body]) =>
      _send('PATCH', path, body: body);

  Future<dynamic> put(String path, [Object? body]) =>
      _send('PUT', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final uri = _uri(path, query);
    final headers = _headers;
    final encoded = body == null ? null : jsonEncode(body);
    late final http.Response res;
    try {
      res = switch (method) {
        'GET' => await http.get(uri, headers: headers),
        'POST' => await http.post(uri, headers: headers, body: encoded),
        'PATCH' => await http.patch(uri, headers: headers, body: encoded),
        'PUT' => await http.put(uri, headers: headers, body: encoded),
        'DELETE' => await http.delete(uri, headers: headers),
        _ => throw ApiException('Metodo non supportato'),
      };
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
          'Impossibile contattare il server. Controlla la connessione e riprova.');
    }
    if (res.statusCode == 204 || res.bodyBytes.isEmpty) return null;
    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      decoded = null;
    }
    if (res.statusCode >= 400) {
      final msg = (decoded is Map && decoded['error'] is String)
          ? decoded['error'] as String
          : 'Errore del server (${res.statusCode})';
      throw ApiException(msg);
    }
    return decoded;
  }
}

final api = ApiClient.instance;

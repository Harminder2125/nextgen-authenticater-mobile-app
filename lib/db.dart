import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenHelper {
  final _storage = const FlutterSecureStorage();

  saveToken(String id, String data) async {
    try {
      await _storage.write(key: id, value: data);
      return {'message': 'Device Authenticated', 'code': 200};
    } catch (e) {
      return {'message': 'Token Not saved', 'code': 0};
    }
  }

  Future<String?> readToken(String id) async {
    String? token = await _storage.read(key: id);
    return token;
  }

  Future<dynamic> deleteToken(String id) async {
    try {
      await _storage.delete(key: id);
      return {'message': 'Token De-Registered', 'code': 200};
    } catch (e) {
      return {'message': 'Token Not deleted', 'code': 0};
    }
  }

  Future<int> getTokenCount() async {
    Map<String, String> allValues = await _storage.readAll();
    return allValues.length;
  }

  Future<List<String>> getAllTokens() async {
    Map<String, String> allValues = await _storage.readAll();

    List<String> tokens = [];
    allValues.forEach((key, value) {
      tokens.add(key);
    });
    return tokens;
  }
}

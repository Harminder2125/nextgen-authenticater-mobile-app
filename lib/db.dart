import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenHelper {
  final _storage = const FlutterSecureStorage();

  saveToken(String token) async {
    await _storage.write(key: 'token', value: token);
    return {'message': 'Device Authenticated', 'code': 200};
  }

  Future<String> readToken() async {
    String token = await _storage.read(key: 'token')??"";
    return token;
  }

  Future<dynamic> deleteToken() async {
        await _storage.delete(key: 'token');
      return {'message': 'Device De-Registered', 'code': 200};
  }
}

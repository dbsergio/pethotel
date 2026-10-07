import 'dart:convert';
import 'package:http/http.dart' as http;
import '../local/local_storage.dart';

class AuthRepository {
  final String baseUrl = const String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8080');

  Future<bool> register(String email, String password, String playerId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'playerId': playerId}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await LocalStorage.prefs.setString('jwt_token', data['token']);
        await LocalStorage.prefs.setString('playerId', data['playerId']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await LocalStorage.prefs.setString('jwt_token', data['token']);
        await LocalStorage.prefs.setString('playerId', data['playerId']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void logout() {
    LocalStorage.prefs.remove('jwt_token');
  }

  bool isLoggedIn() {
    return LocalStorage.prefs.getString('jwt_token') != null;
  }
}

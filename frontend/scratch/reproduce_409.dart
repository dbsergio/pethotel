import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'http://localhost:8080';
  final email = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
  final password = 'password123';
  final playerId = 'player_${DateTime.now().millisecondsSinceEpoch}';

  // 1. Register
  print('Registering...');
  var res = await http.post(
    Uri.parse('$baseUrl/api/auth/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password, 'playerId': playerId}),
  );
  if (res.statusCode != 200) {
    print('Failed to register: ${res.body}');
    return;
  }
  final token = jsonDecode(res.body)['token'];
  final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  print('Registered successfully.');

  // 2. Fetch initial save (should be 404 or empty since we haven't saved)
  print('Fetching save...');
  res = await http.get(Uri.parse('$baseUrl/api/game/save/$playerId'), headers: headers);
  print('Fetch result: ${res.statusCode} - ${res.body}');

  // 3. First save
  print('Sending first save (revision 1)...');
  final save1 = {
    'id': playerId,
    'revision': 1,
    'coins': 100,
  };
  res = await http.post(Uri.parse('$baseUrl/api/game/save'), headers: headers, body: jsonEncode(save1));
  print('Save 1 result: ${res.statusCode} - ${res.body}');
  
  if (res.statusCode == 200) {
    final serverRev = jsonDecode(res.body)['save']['revision'];
    print('Server returned revision: $serverRev');
    
    // 4. Second save
    print('Sending second save (revision $serverRev)...');
    final save2 = {
      'id': playerId,
      'revision': serverRev,
      'coins': 150,
    };
    res = await http.post(Uri.parse('$baseUrl/api/game/save'), headers: headers, body: jsonEncode(save2));
    print('Save 2 result: ${res.statusCode} - ${res.body}');
    
    // 5. What if we send save 2 AGAIN? (Should conflict)
    print('Sending second save AGAIN (revision $serverRev)...');
    res = await http.post(Uri.parse('$baseUrl/api/game/save'), headers: headers, body: jsonEncode(save2));
    print('Save 2 REPEAT result: ${res.statusCode} - ${res.body}');
  }
}

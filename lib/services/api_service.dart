import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({String? baseUrl})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://localhost:5000',
            );

  Future<bool> health() async {
    final res = await http.get(Uri.parse('$baseUrl/health'));
    if (res.statusCode == 200) {
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      return map['ok'] == true;
    }
    throw Exception('Health check failed: ${res.statusCode}');
  }

  Future<List<String>> getTables() async {
    final res = await http.get(Uri.parse('$baseUrl/tables'));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        return '${m['TABLE_SCHEMA']}.${m['TABLE_NAME']}';
      }).toList();
    }
    throw Exception('Failed to load tables: ${res.statusCode}');
  }
}

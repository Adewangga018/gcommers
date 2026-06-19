import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/wilayah_models.dart';

class WilayahService {
  WilayahService({String? baseUrl})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://localhost:5000',
            );

  final String baseUrl;

  Uri _uri(String path, [Map<String, String?> query = const {}]) {
    final filtered = <String, String>{};
    for (final entry in query.entries) {
      if (entry.value != null && entry.value!.isNotEmpty) {
        filtered[entry.key] = entry.value!;
      }
    }
    return Uri.parse('$baseUrl$path').replace(queryParameters: filtered.isEmpty ? null : filtered);
  }

  Future<List<Provinsi>> getProvinsiList() async {
    final response = await http.get(_uri('/wilayah/provinsi'));
    _ensureOk(response);
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => Provinsi.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Kabupaten>> getKabupatenList(int provinsiId) async {
    final response = await http.get(_uri('/wilayah/kabupaten', {'provinsiId': '$provinsiId'}));
    _ensureOk(response);
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => Kabupaten.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Kecamatan>> getKecamatanList(int kabupatenId) async {
    final response = await http.get(_uri('/wilayah/kecamatan', {'kabupatenId': '$kabupatenId'}));
    _ensureOk(response);
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => Kecamatan.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  void _ensureOk(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception('Request failed with status ${response.statusCode}');
    }
  }
}

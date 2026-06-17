import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/commerce_models.dart';

class CommerceService {
  CommerceService({String? baseUrl})
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

  Future<DashboardSummary> getDashboardSummary() async {
    final response = await http.get(_uri('/dashboard/summary'));
    _ensureOk(response);
    return DashboardSummary.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<Product>> getProducts({String? category}) async {
    final response = await http.get(_uri('/products', {'category': category}));
    _ensureOk(response);
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<OrderDetail> createOrder({
    String? userEmail,
    required Map<int, int> quantities,
  }) async {
    final items = quantities.entries
        .where((entry) => entry.value > 0)
        .map((entry) => {
              'productId': entry.key,
              'quantity': entry.value,
            })
        .toList();

    final response = await http.post(
      _uri('/orders'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userEmail': userEmail,
        'items': items,
      }),
    );
    _ensureOk(response);
    return OrderDetail.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<OrderSummary>> getOrders({String? userEmail}) async {
    final response = await http.get(_uri('/orders', {'userEmail': userEmail}));
    _ensureOk(response);
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => OrderSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<OrderDetail> getOrderDetail(String poNumber) async {
    final response = await http.get(_uri('/orders/$poNumber'));
    _ensureOk(response);
    return OrderDetail.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<PaymentResult> payOrder({
    required String poNumber,
    required String method,
  }) async {
    final response = await http.post(
      _uri('/orders/$poNumber/payment'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'method': method}),
    );
    _ensureOk(response);
    return PaymentResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> confirmReceived(String poNumber) async {
    final response = await http.post(
      _uri('/orders/$poNumber/confirm-received'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'accepted': true, 'notes': 'Barang diterima oleh kios'}),
    );
    _ensureOk(response);
  }

  Future<List<ShipmentSummary>> getShipments({String? transportirEmail}) async {
    final response = await http.get(_uri('/shipments', {'transportirEmail': transportirEmail}));
    _ensureOk(response);
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => ShipmentSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TransportirDashboardSummary> getTransportirDashboardSummary({String? transportirEmail}) async {
    final response = await http.get(_uri('/transportir/dashboard-summary', {'transportirEmail': transportirEmail}));
    _ensureOk(response);
    return TransportirDashboardSummary.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<AppNotification>> getNotifications({String? userEmail}) async {
    final response = await http.get(_uri('/notifications', {'userEmail': userEmail}));
    _ensureOk(response);
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAllNotificationsRead({String? userEmail}) async {
    final response = await http.post(
      _uri('/notifications/mark-all-read', {'userEmail': userEmail}),
      headers: const {'Content-Type': 'application/json'},
    );
    _ensureOk(response);
  }

  Future<void> markNotificationRead(int id) async {
    final response = await http.post(
      _uri('/notifications/$id/mark-read'),
      headers: const {'Content-Type': 'application/json'},
    );
    _ensureOk(response);
  }

  void _ensureOk(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String? message;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['message'] is String) {
        message = decoded['message'] as String;
      }
    } catch (_) {
      message = null;
    }

    throw Exception(message ?? 'Request gagal: ${response.statusCode}');
  }
}

class Product {
  const Product({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.stock,
    required this.minimumOrder,
    required this.unit,
    required this.iconName,
    required this.status,
    required this.rating,
    required this.specification,
    this.pajakPphPersen = 0.25,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      code: json['code'] as String? ?? '',
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      minimumOrder: json['minimumOrder'] as int,
      unit: json['unit'] as String,
      iconName: json['iconName'] as String,
      status: json['status'] as String? ?? 'Aktif',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      specification: json['specification'] as String?,
      pajakPphPersen: (json['pajakPphPersen'] as num?)?.toDouble() ?? 0.25,
    );
  }

  final int id;
  final String code;
  final String name;
  final String description;
  final String category;
  final double price;
  final int stock;
  final int minimumOrder;
  final String unit;
  final String iconName;
  final String status;
  final double rating;
  final String? specification;
  final double pajakPphPersen;
}

class OrderSummary {
  const OrderSummary({
    required this.poNumber,
    required this.status,
    required this.statusLabel,
    required this.totalAmount,
    required this.createdAt,
    required this.paymentMethod,
    required this.itemCount,
    this.orderStatus,
    required this.orderStatusLabel,
    required this.paymentStatus,
    required this.paymentStatusLabel,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      poNumber: json['poNumber'] as String,
      status: json['status'] as String,
      statusLabel: json['statusLabel'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      paymentMethod: json['paymentMethod'] as String,
      itemCount: json['itemCount'] as int,
      orderStatus: json['orderStatus'] as String?,
      orderStatusLabel: json['orderStatusLabel'] as String? ?? 'Menunggu Pembayaran',
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      paymentStatusLabel: json['paymentStatusLabel'] as String? ?? 'Pending',
    );
  }

  final String poNumber;
  final String status;
  final String statusLabel;
  final double totalAmount;
  final DateTime createdAt;
  final String paymentMethod;
  final int itemCount;
  /// 4 nilai kontrak: processing/shipping/delivered/cancelled, null sebelum bayar.
  final String? orderStatus;
  final String orderStatusLabel;
  /// Diturunkan dari PaidAt: 'pending' atau 'paid'.
  final String paymentStatus;
  final String paymentStatusLabel;
}

class DashboardSummary {
  const DashboardSummary({
    required this.activeOrderCount,
    required this.completedOrderCount,
    required this.monthlySales,
    required this.recentOrders,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      activeOrderCount: json['activeOrderCount'] as int,
      completedOrderCount: json['completedOrderCount'] as int,
      monthlySales: (json['monthlySales'] as num).toDouble(),
      recentOrders: (json['recentOrders'] as List<dynamic>)
          .map((item) => OrderSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final int activeOrderCount;
  final int completedOrderCount;
  final double monthlySales;
  final List<OrderSummary> recentOrders;
}

class OrderDetail {
  const OrderDetail({
    required this.poNumber,
    required this.status,
    required this.statusLabel,
    required this.vendor,
    required this.paymentMethod,
    required this.subtotal,
    required this.totalAmount,
    required this.createdAt,
    required this.paidAt,
    required this.deliveredAt,
    required this.items,
    required this.timeline,
    this.orderStatus,
    required this.orderStatusLabel,
    this.orderStatusNote,
    required this.paymentStatus,
    required this.paymentStatusLabel,
    this.deliveryAddress,
    this.deliveryKelurahan,
    this.deliveryKodePos,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.driverName,
    this.truckLabel,
    this.policeNumber,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      poNumber: json['poNumber'] as String,
      status: json['status'] as String,
      statusLabel: json['statusLabel'] as String,
      vendor: json['vendor'] as String,
      paymentMethod: json['paymentMethod'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      paidAt: json['paidAt'] == null ? null : DateTime.parse(json['paidAt'] as String),
      deliveredAt: json['deliveredAt'] == null ? null : DateTime.parse(json['deliveredAt'] as String),
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      timeline: (json['timeline'] as List<dynamic>)
          .map((item) => OrderTimeline.fromJson(item as Map<String, dynamic>))
          .toList(),
      orderStatus: json['orderStatus'] as String?,
      orderStatusLabel: json['orderStatusLabel'] as String? ?? 'Menunggu Pembayaran',
      orderStatusNote: json['orderStatusNote'] as String?,
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      paymentStatusLabel: json['paymentStatusLabel'] as String? ?? 'Pending',
      deliveryAddress: json['deliveryAddress'] as String?,
      deliveryKelurahan: json['deliveryKelurahan'] as String?,
      deliveryKodePos: json['deliveryKodePos'] as String?,
      deliveryLatitude: (json['deliveryLatitude'] as num?)?.toDouble(),
      deliveryLongitude: (json['deliveryLongitude'] as num?)?.toDouble(),
      driverName: json['driverName'] as String?,
      truckLabel: json['truckLabel'] as String?,
      policeNumber: json['policeNumber'] as String?,
    );
  }

  final String poNumber;
  final String status;
  final String statusLabel;
  final String vendor;
  final String paymentMethod;
  final double subtotal;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? deliveredAt;
  final List<OrderItem> items;
  final List<OrderTimeline> timeline;
  final String? orderStatus;
  final String orderStatusLabel;
  final String? orderStatusNote;
  final String paymentStatus;
  final String paymentStatusLabel;
  final String? deliveryAddress;
  final String? deliveryKelurahan;
  final String? deliveryKodePos;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? driverName;
  final String? truckLabel;
  final String? policeNumber;
}

class OrderItem {
  const OrderItem({
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productName: json['productName'] as String,
      unit: json['unit'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
    );
  }

  final String productName;
  final String unit;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
}

class OrderTimeline {
  const OrderTimeline({
    required this.title,
    required this.subtitle,
    required this.eventType,
    required this.isActive,
  });

  factory OrderTimeline.fromJson(Map<String, dynamic> json) {
    return OrderTimeline(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      eventType: json['eventType'] as String,
      isActive: json['isActive'] as bool,
    );
  }

  final String title;
  final String subtitle;
  final String eventType;
  final bool isActive;
}

class PaymentResult {
  const PaymentResult({
    required this.poNumber,
    required this.method,
    required this.virtualAccount,
    required this.totalAmount,
    required this.status,
    required this.expiredAt,
    required this.instructions,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      poNumber: json['poNumber'] as String,
      method: json['method'] as String,
      virtualAccount: json['virtualAccount'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'] as String,
      expiredAt: DateTime.parse(json['expiredAt'] as String),
      instructions: (json['instructions'] as List<dynamic>).cast<String>(),
    );
  }

  final String poNumber;
  final String method;
  final String virtualAccount;
  final double totalAmount;
  final String status;
  final DateTime expiredAt;
  final List<String> instructions;
}

class ShipmentSummary {
  const ShipmentSummary({
    required this.shipmentNumber,
    required this.status,
    required this.statusLabel,
    required this.driverName,
    required this.truckLabel,
    required this.policeNumber,
    required this.destinationLabel,
    required this.destinationAddress,
    required this.originLat,
    required this.originLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.createdAt,
    required this.completedAt,
    this.orderId,
    this.poNumber,
    this.warehouseName,
    this.warehouseAddress,
    this.muatInPhotoUrl,
    this.muatOutPhotoUrl,
    this.note,
    this.assignedBy,
    this.muatInCompletedAt,
    this.muatOutCompletedAt,
    this.productId,
    this.productCode,
    this.productName,
    this.quotaTon,
    this.soCode,
  });

  factory ShipmentSummary.fromJson(Map<String, dynamic> json) {
    return ShipmentSummary(
      shipmentNumber: json['shipmentNumber'] as String,
      status: json['status'] as String,
      statusLabel: json['statusLabel'] as String,
      driverName: json['driverName'] as String,
      truckLabel: json['truckLabel'] as String?,
      policeNumber: json['policeNumber'] as String?,
      destinationLabel: json['destinationLabel'] as String?,
      destinationAddress: json['destinationAddress'] as String?,
      originLat: (json['originLat'] as num?)?.toDouble(),
      originLng: (json['originLng'] as num?)?.toDouble(),
      destinationLat: (json['destinationLat'] as num?)?.toDouble(),
      destinationLng: (json['destinationLng'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null ? null : DateTime.parse(json['completedAt'] as String),
      orderId: json['orderId'] as int?,
      poNumber: json['poNumber'] as String?,
      warehouseName: json['warehouseName'] as String?,
      warehouseAddress: json['warehouseAddress'] as String?,
      muatInPhotoUrl: json['muatInPhotoUrl'] as String?,
      muatOutPhotoUrl: json['muatOutPhotoUrl'] as String?,
      note: json['note'] as String?,
      assignedBy: json['assignedBy'] as String?,
      muatInCompletedAt:
          json['muatInCompletedAt'] == null ? null : DateTime.parse(json['muatInCompletedAt'] as String),
      muatOutCompletedAt:
          json['muatOutCompletedAt'] == null ? null : DateTime.parse(json['muatOutCompletedAt'] as String),
      productId: json['productId'] as int?,
      productCode: json['productCode'] as String?,
      productName: json['productName'] as String?,
      quotaTon: (json['quotaTon'] as num?)?.toDouble(),
      soCode: json['soCode'] as String?,
    );
  }

  final String shipmentNumber;
  final String status;
  final String statusLabel;
  final String driverName;
  final String? truckLabel;
  final String? policeNumber;
  final String? destinationLabel;
  final String? destinationAddress;
  final double? originLat;
  final double? originLng;
  final double? destinationLat;
  final double? destinationLng;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int? orderId;
  final String? poNumber;
  final String? warehouseName;
  final String? warehouseAddress;
  final String? muatInPhotoUrl;
  final String? muatOutPhotoUrl;
  final String? note;
  final String? assignedBy;
  final DateTime? muatInCompletedAt;
  final DateTime? muatOutCompletedAt;
  final int? productId;
  final String? productCode;
  final String? productName;
  final double? quotaTon;
  final String? soCode;
}

class TransportirDashboardSummary {
  const TransportirDashboardSummary({
    required this.totalShipments,
    required this.activeShipments,
    required this.activeShipment,
  });

  factory TransportirDashboardSummary.fromJson(Map<String, dynamic> json) {
    return TransportirDashboardSummary(
      totalShipments: json['totalShipments'] as int,
      activeShipments: json['activeShipments'] as int,
      activeShipment: json['activeShipment'] == null
          ? null
          : ShipmentSummary.fromJson(json['activeShipment'] as Map<String, dynamic>),
    );
  }

  final int totalShipments;
  final int activeShipments;
  final ShipmentSummary? activeShipment;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.isRead,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool,
    );
  }

  final int id;
  final String title;
  final String description;
  final DateTime createdAt;
  final bool isRead;

  AppNotification copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

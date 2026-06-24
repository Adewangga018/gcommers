public sealed record ProductDto(
    int Id,
    string Code,
    string Name,
    string Description,
    string Category,
    decimal Price,
    int Stock,
    int MinimumOrder,
    string Unit,
    string IconName,
    string Status,
    decimal Rating,
    string? Specification,
    decimal BiayaPengirimanPerKg = 50m,
    decimal PajakPphPersen = 0.25m);

public sealed record UpsertProductRegionPriceRequest(
    int ProductId,
    string ProductName,
    string ProductCode,
    string Region,
    decimal HargaSatuan,
    decimal BiayaPengirimanPerKg,
    decimal PajakPphPersen,
    decimal QtyAvailable,
    string? SetBy);

public sealed record CreateOrderItemRequest(int ProductId, int Quantity);

public sealed record CreateOrderRequest(string? UserEmail, string? Region, string? Kecamatan, IReadOnlyList<CreateOrderItemRequest> Items)
{
    public string? Validate()
    {
        if (Items.Count == 0)
        {
            return "Minimal satu produk harus dipilih.";
        }

        if (Items.Any(item => item.ProductId <= 0 || item.Quantity <= 0))
        {
            return "Produk dan jumlah pesanan tidak valid.";
        }

        return null;
    }
}

public sealed record OrderSummaryDto(
    string PoNumber,
    string Status,
    string StatusLabel,
    decimal TotalAmount,
    DateTimeOffset CreatedAt,
    string PaymentMethod,
    int ItemCount,
    string? OrderStatus,
    string OrderStatusLabel,
    string PaymentStatus,
    string PaymentStatusLabel);

public sealed record OrderDetailDto(
    string PoNumber,
    string Status,
    string StatusLabel,
    string Vendor,
    string PaymentMethod,
    decimal Subtotal,
    decimal TaxAmount,
    decimal ShippingAmount,
    decimal TotalAmount,
    DateTimeOffset CreatedAt,
    DateTimeOffset? PaidAt,
    DateTimeOffset? DeliveredAt,
    IReadOnlyList<OrderItemDto> Items,
    IReadOnlyList<OrderTimelineDto> Timeline,
    string? OrderStatus,
    string OrderStatusLabel,
    string? OrderStatusNote,
    string PaymentStatus,
    string PaymentStatusLabel,
    string? DeliveryAddress = null,
    string? DeliveryKelurahan = null,
    string? DeliveryKodePos = null,
    double? DeliveryLatitude = null,
    double? DeliveryLongitude = null);

public sealed record OrderItemDto(
    string ProductName,
    string Unit,
    int Quantity,
    decimal UnitPrice,
    decimal TotalPrice);

public sealed record OrderTimelineDto(
    string Title,
    string Subtitle,
    string EventType,
    bool IsActive);

public sealed record PaymentRequest(string Method);

public sealed record PaymentResponse(
    string PoNumber,
    string Method,
    string VirtualAccount,
    decimal TotalAmount,
    string Status,
    DateTimeOffset ExpiredAt,
    IReadOnlyList<string> Instructions);

public sealed record ConfirmReceivedRequest(bool Accepted, string? Notes);

public sealed record DashboardSummaryDto(
    int ActiveOrderCount,
    int CompletedOrderCount,
    decimal MonthlySales,
    IReadOnlyList<OrderSummaryDto> RecentOrders);

public sealed record ShipmentSummaryDto(
    string ShipmentNumber,
    string Status,
    string StatusLabel,
    string DriverName,
    string? TruckLabel,
    string? PoliceNumber,
    string? DestinationLabel,
    string? DestinationAddress,
    double? OriginLat,
    double? OriginLng,
    double? DestinationLat,
    double? DestinationLng,
    DateTimeOffset CreatedAt,
    DateTimeOffset? CompletedAt,
    int? OrderId,
    string? PoNumber,
    string? WarehouseName,
    string? WarehouseAddress,
    string? MuatInPhotoUrl,
    string? MuatOutPhotoUrl,
    string? Note,
    string? AssignedBy,
    DateTimeOffset? MuatInCompletedAt,
    DateTimeOffset? MuatOutCompletedAt);

public sealed record ShipmentPhotoUploadResponse(
    string ShipmentNumber,
    string Status,
    string StatusLabel,
    string PhotoUrl,
    DateTimeOffset CompletedAt);

public sealed record TransportirDashboardSummaryDto(
    int TotalShipments,
    int ActiveShipments,
    ShipmentSummaryDto? ActiveShipment);

public sealed record NotificationDto(
    int Id,
    string Title,
    string Description,
    DateTimeOffset CreatedAt,
    bool IsRead);

public sealed record UploadKtpResponse(string FileName, string Url);

public sealed record ProductDto(
    int Id,
    string Name,
    string Description,
    string Category,
    decimal Price,
    int Stock,
    int MinimumOrder,
    string Unit,
    string IconName);

public sealed record CreateOrderItemRequest(int ProductId, int Quantity);

public sealed record CreateOrderRequest(string? UserEmail, IReadOnlyList<CreateOrderItemRequest> Items)
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
    int ItemCount);

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
    IReadOnlyList<OrderTimelineDto> Timeline);

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
    string Status);

public sealed record ConfirmReceivedRequest(bool Accepted, string? Notes);

public sealed record DashboardSummaryDto(
    int ActiveOrderCount,
    int CompletedOrderCount,
    decimal MonthlySales,
    IReadOnlyList<OrderSummaryDto> RecentOrders);

public sealed record NotificationDto(
    int Id,
    string Title,
    string Description,
    DateTimeOffset CreatedAt,
    bool IsRead);

public sealed record UploadKtpResponse(string FileName, string Url);

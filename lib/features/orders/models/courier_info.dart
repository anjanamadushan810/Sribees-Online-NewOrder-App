/// The `courier` block of `GET /admin/orders/{id}` (admin_orders._courier_block),
/// read the same way the admin web CourierPanel reads it.
class CourierInfo {
  const CourierInfo({
    this.shipmentId,
    this.waybill,
    this.isCod = false,
    this.codAmount = 0,
    this.bookingStatus,
    this.trackingStatus,
    this.trackingUrl,
    this.trackingUpdatedAt,
    this.pickupLocationName,
    this.handoverRequired = false,
    this.handoverVerified,
    this.codCollected = false,
    this.codCollectedAmount,
    this.codShortfall,
    this.failureNote,
    this.willRetry,
    this.canRequestPickup = false,
    this.canRefreshTracking = false,
    this.branchPickupRegistered = true,
  });

  final String? shipmentId;
  final String? waybill;
  final bool isCod;
  final double codAmount;

  /// Ours: pending | booked | failed.
  final String? bookingStatus;

  /// Theirs: booked, picked_up, in_transit, out_for_delivery, delivered, failed, returned, cancelled.
  final String? trackingStatus;
  final String? trackingUrl;
  final DateTime? trackingUpdatedAt;
  final String? pickupLocationName;
  final bool handoverRequired;
  final bool? handoverVerified;

  /// COD only: `delivered` alone does NOT mean the cash was collected.
  final bool codCollected;
  final double? codCollectedAmount;
  final double? codShortfall;

  /// Rider free text on a failed parcel. Shown, never branched on.
  final String? failureNote;
  final bool? willRetry;

  final bool canRequestPickup;
  final bool canRefreshTracking;
  final bool branchPickupRegistered;

  /// Booked with SribeesExpress: there is a waybill, so there is a label.
  bool get booked => (shipmentId ?? '').isNotEmpty;

  bool get bookingFailed => bookingStatus == 'failed';

  static String? _s(Object? v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static double? _dn(Object? v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}');

  factory CourierInfo.fromJson(Map<String, dynamic> j) => CourierInfo(
        shipmentId: _s(j['shipment_id']),
        waybill: _s(j['waybill']),
        isCod: j['payment_method'] == 'cod',
        codAmount: _dn(j['cod_amount']) ?? 0,
        bookingStatus: _s(j['booking_status']),
        trackingStatus: _s(j['tracking_status']),
        trackingUrl: _s(j['tracking_url']),
        trackingUpdatedAt: DateTime.tryParse('${j['tracking_updated_at'] ?? ''}'),
        pickupLocationName: _s(j['pickup_location_name']),
        handoverRequired: j['handover_required'] == true,
        handoverVerified: j['handover_verified'] is bool ? j['handover_verified'] as bool : null,
        codCollected: j['cod_collected'] == true,
        codCollectedAmount: _dn(j['cod_collected_amount']),
        codShortfall: _dn(j['cod_shortfall']),
        failureNote: _s(j['failure_note']),
        willRetry: j['will_retry'] is bool ? j['will_retry'] as bool : null,
        canRequestPickup: j['can_request_pickup'] == true,
        canRefreshTracking: j['can_refresh_tracking'] == true,
        branchPickupRegistered: j['branch_pickup_registered'] != false,
      );
}

/// `GET /admin/orders/{id}/courier/label` -> data. Mirrors SribeesExpress's
/// ShippingLabelOut; the barcode is drawn here from [waybillId].
class CourierLabel {
  const CourierLabel({
    required this.waybillId,
    required this.orderNumber,
    this.bookedAt,
    this.senderName,
    this.senderPhone,
    required this.recipientName,
    required this.recipientPhone,
    required this.recipientAddress,
    this.destinationCity,
    this.destinationDistrict,
    required this.weightKg,
    required this.codAmount,
    required this.isCod,
    required this.deliveryCharge,
    required this.itemCount,
    required this.requiresHandoverCode,
  });

  final String waybillId;
  final String orderNumber;
  final DateTime? bookedAt;
  final String? senderName;
  final String? senderPhone;
  final String recipientName;
  final String recipientPhone;
  final String recipientAddress;
  final String? destinationCity;
  final String? destinationDistrict;
  final String weightKg;
  final double codAmount;
  final bool isCod;
  final String deliveryCharge;
  final int itemCount;
  final bool requiresHandoverCode;

  factory CourierLabel.fromJson(Map<String, dynamic> j) => CourierLabel(
        waybillId: '${j['waybill_id'] ?? ''}',
        orderNumber: '${j['order_number'] ?? ''}',
        bookedAt: DateTime.tryParse('${j['booked_at'] ?? ''}'),
        senderName: CourierInfo._s(j['sender_name']),
        senderPhone: CourierInfo._s(j['sender_phone']),
        recipientName: '${j['recipient_name'] ?? ''}',
        recipientPhone: '${j['recipient_phone'] ?? ''}',
        recipientAddress: '${j['recipient_address'] ?? ''}',
        destinationCity: CourierInfo._s(j['destination_city']),
        destinationDistrict: CourierInfo._s(j['destination_district']),
        weightKg: '${j['weight_kg'] ?? ''}',
        codAmount: CourierInfo._dn(j['cod_amount']) ?? 0,
        isCod: j['is_cod'] == true,
        deliveryCharge: '${j['delivery_charge'] ?? ''}',
        itemCount: (j['item_count'] as num?)?.toInt() ?? 0,
        requiresHandoverCode: j['requires_handover_code'] == true,
      );
}

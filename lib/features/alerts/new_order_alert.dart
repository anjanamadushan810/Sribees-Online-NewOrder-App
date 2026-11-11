/// What a new-order push carries (backend: staff_order_alert_service.py).
class NewOrderAlert {
  const NewOrderAlert({required this.orderId, required this.orderNumber, this.branchId});

  final String orderId;
  final String orderNumber;
  final String? branchId;

  /// The push's `data`, or null when it is not a new-order alert.
  static NewOrderAlert? fromData(Map<String, dynamic> data) {
    if (data['type'] != 'new_order') return null;
    final id = '${data['order_id'] ?? ''}'.trim();
    if (id.isEmpty) return null;
    final branch = '${data['branch_id'] ?? ''}'.trim();
    return NewOrderAlert(
      orderId: id,
      orderNumber: '${data['order_number'] ?? ''}'.trim(),
      branchId: branch.isEmpty ? null : branch,
    );
  }
}

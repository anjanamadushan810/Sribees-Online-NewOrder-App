/// Admin roles as the backend names them (`admin_role_enum`).
enum AdminRole {
  superAdmin('super_admin'),
  branchManager('branch_manager'),
  marketingManager('marketing_manager'),
  inventoryManager('inventory_manager'),
  customerSupport('customer_support'),
  staff('staff'),
  unknown('');

  const AdminRole(this.wire);

  /// The backend's spelling.
  final String wire;

  static AdminRole fromWire(String? value) {
    final v = value?.trim().toLowerCase();
    return AdminRole.values.firstWhere(
      (r) => r != AdminRole.unknown && r.wire == v,
      orElse: () => AdminRole.unknown,
    );
  }
}

/// The signed-in admin, as returned by `/admin/auth/login` and `/profile`.
class AdminUser {
  final String adminId;
  final String email;
  final String fullName;
  final AdminRole role;

  /// Custom role name for delegated staff accounts (e.g. "Packer").
  final String? roleName;
  final String? branchId;
  final bool isActive;

  /// Effective grants as "resource:action" (e.g. "orders:update").
  final Set<String> permissions;

  const AdminUser({
    required this.adminId,
    required this.email,
    required this.fullName,
    required this.role,
    this.roleName,
    this.branchId,
    this.isActive = true,
    this.permissions = const {},
  });

  bool get isSuperAdmin => role == AdminRole.superAdmin;

  /// Sees every branch. Mirrors the backend's `inject_branch_filter`:
  /// super admin always; customer support only when no branch is assigned.
  /// Display only -- the server enforces scope on every request.
  bool get isUnscoped =>
      isSuperAdmin ||
      (role == AdminRole.customerSupport && (branchId == null || branchId!.isEmpty));

  bool can(String resource, String action) =>
      isSuperAdmin || permissions.contains('$resource:$action');

  bool get canReadOrders => can('orders', 'read');
  bool get canUpdateOrders => can('orders', 'update');

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    final perms = <String>{};
    final rawPerms = json['permissions'];
    if (rawPerms is List) {
      for (final p in rawPerms) {
        if (p is Map && p['resource'] != null && p['action'] != null) {
          perms.add('${p['resource']}:${p['action']}');
        } else if (p is String && p.contains(':')) {
          perms.add(p);
        }
      }
    }
    final branch = (json['branchId'] ?? json['branch_id'])?.toString();
    return AdminUser(
      adminId: (json['adminId'] ?? json['admin_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['full_name'] ?? '').toString(),
      role: AdminRole.fromWire(json['role']?.toString()),
      roleName: (json['roleName'] ?? json['role_name'])?.toString(),
      branchId: (branch == null || branch.isEmpty) ? null : branch,
      isActive: (json['isActive'] ?? json['is_active'] ?? true) == true,
      permissions: perms,
    );
  }

  Map<String, dynamic> toJson() => {
        'adminId': adminId,
        'email': email,
        'fullName': fullName,
        'role': role.wire,
        'roleName': roleName,
        'branchId': branchId,
        'isActive': isActive,
        'permissions': [
          for (final p in permissions)
            {'resource': p.split(':').first, 'action': p.split(':').last},
        ],
      };
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sribees_new_orders/features/auth/models/admin_user.dart';

import '../../helpers/fakes.dart';

void main() {
  test('reads the backend camelCase admin with its permission grants', () {
    final u = AdminUser.fromJson(adminJson(role: 'staff', roleName: 'Packer',
        perms: ['orders:read', 'products:read']));
    expect(u.role, AdminRole.staff);
    expect(u.roleName, 'Packer');
    expect(u.branchId, 'B-1');
    expect(u.canReadOrders, isTrue);
    expect(u.canUpdateOrders, isFalse);
    expect(u.permissions, {'orders:read', 'products:read'});
  });

  test('survives a round trip through the cache', () {
    final u = AdminUser.fromJson(adminJson());
    final back = AdminUser.fromJson(u.toJson());
    expect(back.role, u.role);
    expect(back.branchId, u.branchId);
    expect(back.permissions, u.permissions);
  });

  test('unscoped = super admin, or customer support with no branch', () {
    expect(AdminUser.fromJson(adminJson(role: 'super_admin', branchId: null)).isUnscoped, isTrue);
    expect(AdminUser.fromJson(adminJson(role: 'customer_support', branchId: null)).isUnscoped,
        isTrue);
    expect(AdminUser.fromJson(adminJson(role: 'customer_support')).isUnscoped, isFalse);
    expect(AdminUser.fromJson(adminJson(role: 'branch_manager')).isUnscoped, isFalse);
  });

  test('an unknown role is not treated as any known role', () {
    final u = AdminUser.fromJson(adminJson(role: 'owner'));
    expect(u.role, AdminRole.unknown);
    expect(u.isSuperAdmin, isFalse);
  });

  test('an empty branch id counts as no branch', () {
    expect(AdminUser.fromJson(adminJson(branchId: '')).branchId, isNull);
  });
}

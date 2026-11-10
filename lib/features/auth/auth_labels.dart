import '../../l10n/generated/app_localizations.dart';
import 'models/admin_user.dart';
import 'models/auth_state.dart';

/// Translated words for auth values. Kept apart from the models so the
/// models stay free of Flutter.
extension AuthFailureLabel on AuthFailure {
  String label(AppLocalizations t) => switch (this) {
        AuthFailure.invalidCredentials => t.errInvalidCredentials,
        AuthFailure.noOrderAccess => t.errNoOrderAccess,
        AuthFailure.noBranch => t.errNoBranch,
        AuthFailure.sessionExpired => t.errSessionExpired,
        AuthFailure.offline => t.errOffline,
        AuthFailure.timeout => t.errTimeout,
        AuthFailure.server => t.errServer,
        AuthFailure.unknown => t.errUnknown,
      };
}

extension AdminRoleLabel on AdminRole {
  String label(AppLocalizations t) => switch (this) {
        AdminRole.superAdmin => t.roleSuperAdmin,
        AdminRole.branchManager => t.roleBranchManager,
        AdminRole.marketingManager => t.roleMarketingManager,
        AdminRole.inventoryManager => t.roleInventoryManager,
        AdminRole.customerSupport => t.roleCustomerSupport,
        AdminRole.staff => t.roleStaff,
        AdminRole.unknown => t.roleUnknown,
      };
}

/// Staff accounts carry a custom role name ("Packer"); show it when present.
String roleTitle(AdminUser user, AppLocalizations t) {
  final custom = user.roleName?.trim();
  if (user.role == AdminRole.staff && custom != null && custom.isNotEmpty) {
    return custom;
  }
  return user.role.label(t);
}

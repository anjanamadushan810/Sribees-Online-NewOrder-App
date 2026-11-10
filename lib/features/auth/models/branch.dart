/// A Sribees store branch (`/admin/branches`).
class Branch {
  final String branchId;
  final String name;
  final String code;
  final String? district;
  final bool isActive;

  const Branch({
    required this.branchId,
    required this.name,
    this.code = '',
    this.district,
    this.isActive = true,
  });

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
        branchId: (json['branch_id'] ?? json['branchId'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        code: (json['code'] ?? '').toString(),
        district: json['district']?.toString(),
        isActive: (json['is_active'] ?? json['isActive'] ?? true) == true,
      );

  @override
  bool operator ==(Object other) =>
      other is Branch && other.branchId.toLowerCase() == branchId.toLowerCase();

  @override
  int get hashCode => branchId.toLowerCase().hashCode;
}

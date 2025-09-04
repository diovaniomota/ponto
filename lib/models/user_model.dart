class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String employeeId;
  final String role;
  final String? department;
  final String? position;
  final double? hourlyWage;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.employeeId,
    required this.role,
    this.department,
    this.position,
    this.hourlyWage,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      employeeId: json['employee_id'] as String,
      role: json['role'] as String,
      department: json['department'] as String?,
      position: json['position'] as String?,
      hourlyWage: json['hourly_wage']?.toDouble(),
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'employee_id': employeeId,
      'role': role,
      'department': department,
      'position': position,
      'hourly_wage': hourlyWage,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isEmployee => role == 'employee';

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? employeeId,
    String? role,
    String? department,
    String? position,
    double? hourlyWage,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      employeeId: employeeId ?? this.employeeId,
      role: role ?? this.role,
      department: department ?? this.department,
      position: position ?? this.position,
      hourlyWage: hourlyWage ?? this.hourlyWage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
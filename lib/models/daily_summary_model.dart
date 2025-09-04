class DailySummaryModel {
  final String id;
  final String userId;
  final DateTime workDate;
  final DateTime? clockIn;
  final DateTime? lunchOut;
  final DateTime? lunchIn;
  final DateTime? clockOut;
  final double totalHours;
  final int lunchDurationMinutes;
  final double overtimeHours;
  final DayStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailySummaryModel({
    required this.id,
    required this.userId,
    required this.workDate,
    this.clockIn,
    this.lunchOut,
    this.lunchIn,
    this.clockOut,
    required this.totalHours,
    required this.lunchDurationMinutes,
    required this.overtimeHours,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailySummaryModel.fromJson(Map<String, dynamic> json) {
    return DailySummaryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      workDate: DateTime.parse(json['work_date'] as String),
      clockIn: json['clock_in'] != null ? DateTime.parse(json['clock_in'] as String) : null,
      lunchOut: json['lunch_out'] != null ? DateTime.parse(json['lunch_out'] as String) : null,
      lunchIn: json['lunch_in'] != null ? DateTime.parse(json['lunch_in'] as String) : null,
      clockOut: json['clock_out'] != null ? DateTime.parse(json['clock_out'] as String) : null,
      totalHours: (json['total_hours'] ?? 0).toDouble(),
      lunchDurationMinutes: json['lunch_duration_minutes'] ?? 0,
      overtimeHours: (json['overtime_hours'] ?? 0).toDouble(),
      status: DayStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'work_date': workDate.toIso8601String().split('T')[0],
      'clock_in': clockIn?.toIso8601String(),
      'lunch_out': lunchOut?.toIso8601String(),
      'lunch_in': lunchIn?.toIso8601String(),
      'clock_out': clockOut?.toIso8601String(),
      'total_hours': totalHours,
      'lunch_duration_minutes': lunchDurationMinutes,
      'overtime_hours': overtimeHours,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get formattedTotalHours {
    final hours = totalHours.floor();
    final minutes = ((totalHours - hours) * 60).round();
    return "${hours}h ${minutes}min";
  }

  String get formattedLunchDuration {
    final hours = lunchDurationMinutes ~/ 60;
    final minutes = lunchDurationMinutes % 60;
    return hours > 0 ? "${hours}h ${minutes}min" : "${minutes}min";
  }
}

enum DayStatus {
  complete('complete', 'Completo'),
  incomplete('incomplete', 'Incompleto'),
  missing('missing', 'Faltou');

  const DayStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static DayStatus fromString(String value) {
    return DayStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => DayStatus.incomplete,
    );
  }
}
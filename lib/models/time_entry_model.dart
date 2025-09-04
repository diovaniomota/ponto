class TimeEntryModel {
  final String id;
  final String userId;
  final TimeEntryType entryType;
  final DateTime timestamp;
  final double? locationLat;
  final double? locationLng;
  final String? notes;
  final DateTime createdAt;

  TimeEntryModel({
    required this.id,
    required this.userId,
    required this.entryType,
    required this.timestamp,
    this.locationLat,
    this.locationLng,
    this.notes,
    required this.createdAt,
  });

  factory TimeEntryModel.fromJson(Map<String, dynamic> json) {
    return TimeEntryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      entryType: TimeEntryType.fromString(json['entry_type'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      locationLat: json['location_lat']?.toDouble(),
      locationLng: json['location_lng']?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'entry_type': entryType.value,
      'timestamp': timestamp.toIso8601String(),
      'location_lat': locationLat,
      'location_lng': locationLng,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedTime {
    return "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
  }

  String get formattedDate {
    return "${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year}";
  }
}

enum TimeEntryType {
  clockIn('clock_in', 'Entrada'),
  lunchOut('lunch_out', 'Saída Almoço'),
  lunchIn('lunch_in', 'Volta Almoço'),
  clockOut('clock_out', 'Saída');

  const TimeEntryType(this.value, this.displayName);

  final String value;
  final String displayName;

  static TimeEntryType fromString(String value) {
    return TimeEntryType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TimeEntryType.clockIn,
    );
  }
}
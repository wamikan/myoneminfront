class MeasurementHistory {
  final Duration target;
  final Duration actual;
  final DateTime timestamp;

  MeasurementHistory({required this.target, required this.actual, required this.timestamp});

  Map<String, dynamic> toJson() => {
    'target': target.inSeconds,
    'actual': actual.inSeconds,
    'timestamp': timestamp.toIso8601String(),
  };
  factory MeasurementHistory.fromJson(Map<String, dynamic> map) => MeasurementHistory(
    target: Duration(seconds: map['target']),
    actual: Duration(seconds: map['actual']),
    timestamp: DateTime.parse(map['timestamp']),
  );
}

class Schedule {
  final String title;
  final Duration duration;
  final List<MeasurementHistory> histories;

  Schedule({
    required this.title,
    required this.duration,
    this.histories = const [],
  });

  Schedule copyWith({String? title, Duration? duration, List<MeasurementHistory>? histories}) {
    return Schedule(
      title: title ?? this.title,
      duration: duration ?? this.duration,
      histories: histories ?? List<MeasurementHistory>.from(this.histories),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'durationMinutes': duration.inMinutes,
    'histories': histories.map((h) => h.toJson()).toList(),
  };
  factory Schedule.fromJson(Map<String, dynamic> map) {
    final List<MeasurementHistory> his = (map['histories'] as List?)?.map((e) => MeasurementHistory.fromJson(e)).toList() ?? [];
    return Schedule(
      title: map['title'] as String,
      duration: Duration(minutes: (map['durationMinutes'] as num).toInt()),
      histories: his,
    );
  }
}

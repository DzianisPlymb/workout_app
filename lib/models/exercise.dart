class Exercise {
  int? id;
  int workoutId;
  String name;
  int durationSeconds; // Время на выполнение упражнения

  Exercise({
    this.id,
    required this.workoutId,
    required this.name,
    required this.durationSeconds,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'workout_id': workoutId,
      'name': name,
      'duration_seconds': durationSeconds,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as int?,
      workoutId: map['workout_id'] as int,
      name: map['name'] as String,
      durationSeconds: map['duration_seconds'] as int,
    );
  }
}
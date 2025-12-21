class Workout {
  int? id;
  int userId;
  String title;
  String description;
  int durationMinutes;

  Workout({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.durationMinutes,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId,
      'title': title,
      'description': description,
      'duration_minutes': durationMinutes,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      durationMinutes: map['duration_minutes'] as int,
    );
  }
}

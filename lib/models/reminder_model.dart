class Reminder {
  final int id;
  final String title;
  final String description;
  final DateTime scheduledTime;

  Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.scheduledTime,
  });

  // Convert Reminder to a Map (useful for storing in databases or APIs)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'scheduledTime': scheduledTime.toIso8601String(),
    };
  }

  // Create Reminder from a Map
  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      scheduledTime: DateTime.parse(map['scheduledTime']),
    );
  }
}

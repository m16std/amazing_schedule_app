class Schedule {
  final int id;
  final int day;
  final int weekType; // 0 для белой недели, 1 для зеленой недели
  final String startTime;
  final String endTime;
  final String subject;
  final String teacher;
  final String room;
  final String type; // Лекция, Практика, Лабораторная работа

  Schedule({
    required this.id,
    required this.day,
    required this.weekType,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.type,
  });

  // Метод для преобразования Map (полученного из базы данных) в объект Schedule
  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'],
      day: map['day'],
      weekType: map['weekType'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      subject: map['subject'],
      teacher: map['teacher'],
      room: map['room'],
      type: map['type'],
    );
  }

  // Метод для преобразования объекта Schedule в Map (для вставки в базу данных)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'day': day,
      'weekType': weekType,
      'startTime': startTime,
      'endTime': endTime,
      'subject': subject,
      'teacher': teacher,
      'room': room,
      'type': type,
    };
  }
}

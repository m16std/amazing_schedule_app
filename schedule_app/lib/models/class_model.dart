class Class {
  final int id;
  final int semesterId;
  final String subject;
  final String teacher;
  final String room;
  final int type;
  final int num;
  final int day;
  final int periodicity;
  final int week;

  Class({
    required this.id,
    required this.semesterId,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.type,
    required this.num,
    required this.day,
    required this.periodicity,
    required this.week,
  });

  factory Class.fromMap(Map<String, dynamic> map) {
    return Class(
      id: map['cls_id'],
      semesterId: map['smt_id'],
      subject: map['cls_subject'],
      teacher: map['cls_teacher'],
      room: map['cls_room'],
      type: map['cls_type'],
      num: map['cls_num'],
      day: map['cls_day'],
      periodicity: map['cls_periodicity'],
      week: map['cls_week'],
    );
  }
}

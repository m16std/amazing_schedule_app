class Message {
  final int id;
  final String text;
  final DateTime date;

  Message({
    required this.id,
    required this.text,
    required this.date,
  });

  // Метод для преобразования Map (полученного из базы данных) в объект Message
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['msg_id'],
      text: map['msg_text'],
      date: map['msg_date'],
    );
  }
}

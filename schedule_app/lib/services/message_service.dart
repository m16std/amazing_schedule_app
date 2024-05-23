import 'package:postgres/postgres.dart';
import '../models/message.dart';

class MessageService {
  PostgreSQLConnection _createConnection() {
    return PostgreSQLConnection(
      'localhost',
      5432,
      'schedule_db',
      username: 'postgres',
      password: "'",
    );
  }

  Future<List<Message>> fetchMessages() async {
    final connection = _createConnection();
    await connection.open();

    List<List<dynamic>> results = await connection.query(
      'SELECT msg_id, msg_text, msg_date FROM message ORDER BY msg_date DESC',
    );

    await connection.close();

    return results.map((row) {
      return Message.fromMap({
        'msg_id': row[0],
        'msg_text': row[1],
        'msg_date': row[2],
      });
    }).toList();
  }
}

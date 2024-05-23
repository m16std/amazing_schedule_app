import 'package:postgres/postgres.dart';
import '../models/class_model.dart';

class ClassService {
  PostgreSQLConnection _createConnection() {
    return PostgreSQLConnection(
      'localhost',
      5432,
      'schedule_db',
      username: 'postgres',
      password: "'",
    );
  }

  Future<List<Class>> fetchClasses(int semesterId, int currentWeek) async {
    final connection = _createConnection();
    await connection.open();

    List<List<dynamic>> results = await connection.query('''
      SELECT * FROM class 
      WHERE smt_id = @semesterId 
        AND (cls_periodicity = 1 
        OR (cls_periodicity = 0 AND cls_week = @currentWeek) 
        OR (cls_periodicity = 2 AND MOD(cls_week, 2) = MOD(@currentWeek, 2)))
      ORDER BY cls_day, cls_num, cls_type DESC
    ''', substitutionValues: {
      'semesterId': semesterId,
      'currentWeek': currentWeek,
    });

    await connection.close();

    return results.map((row) {
      return Class.fromMap({
        'cls_id': row[0],
        'smt_id': row[1],
        'cls_subject': row[2],
        'cls_teacher': row[3],
        'cls_room': row[4],
        'cls_type': row[5],
        'cls_num': row[6],
        'cls_day': row[7],
        'cls_periodicity': row[8],
        'cls_week': row[9],
      });
    }).toList();
  }
}

import 'package:postgres/postgres.dart';

class SemesterService {
  PostgreSQLConnection _createConnection() {
    return PostgreSQLConnection(
      'localhost',
      5432,
      'schedule_db',
      username: 'postgres',
      password: "'",
    );
  }

  Future<List<int>> fetchSemestersForGroup(int groupId) async {
    final connection = _createConnection();
    await connection.open();

    List<List<dynamic>> results = await connection.query('''
      SELECT DISTINCT smt_num 
      FROM semester 
      WHERE grp_id = @groupId
    ''', substitutionValues: {
      'groupId': groupId,
    });

    await connection.close();

    return results.map((row) => row[0] as int).toList();
  }
}

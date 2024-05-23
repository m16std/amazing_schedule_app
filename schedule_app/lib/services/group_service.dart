import 'package:postgres/postgres.dart';

class GroupService {
  PostgreSQLConnection _createConnection() {
    return PostgreSQLConnection(
      'localhost',
      5432,
      'schedule_db',
      username: 'postgres',
      password: "'",
    );
  }

  Future<List<Map<String, dynamic>>> fetchUserGroups(int userId) async {
    final connection = _createConnection();
    await connection.open();

    List<List<dynamic>> results = await connection.query('''
      SELECT g.grp_id, g.grp_name 
      FROM cnt_grp cg 
      JOIN groups g ON cg.grp_id = g.grp_id 
      WHERE cg.cnt_id = @userId
    ''', substitutionValues: {
      'userId': userId,
    });

    await connection.close();

    return results
        .map((row) => {
              'grp_id': row[0],
              'grp_name': row[1],
            })
        .toList();
  }
}

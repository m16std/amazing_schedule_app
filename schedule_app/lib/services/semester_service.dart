import 'package:postgres/postgres.dart';
import 'package:schedule_app/services/auth_service.dart';

class SemesterService {
  Future<List<int>> fetchSemestersForGroup(int groupId) async {
    final authService = AuthService();
    PostgreSQLConnection connection = authService.createConnection();
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

import 'package:postgres/postgres.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService extends ChangeNotifier {
  AuthService() {
    createConnection();
  }

  PostgreSQLConnection createConnection() {
    return PostgreSQLConnection(
      'localhost',
      5432,
      'schedule_db',
      username: 'postgres',
      password: "'",
    );
  }

  int? _currentUserId;
  int? get currentUserId => _currentUserId;

  Future<bool> login(String username, String password) async {
    final connection = createConnection();
    await connection.open();

    final passwordHash = md5.convert(utf8.encode(password)).toString();
    List<List<dynamic>> results = await connection.query('''
      SELECT cnt_id FROM client WHERE cnt_login = @username AND cnt_pass = @passwordHash
    ''', substitutionValues: {
      'username': username,
      'passwordHash': passwordHash,
    });

    await connection.close();

    if (results.isNotEmpty) {
      _currentUserId = results[0][0];

      return true;
    }

    return false;
  }

  Future<bool> isAdmin() async {
    final connection = createConnection();
    await connection.open();

    List<List<dynamic>> results = await connection.query('''
      SELECT cnt_type FROM client WHERE cnt_id = @currentUserId
    ''', substitutionValues: {
      'currentUserId': _currentUserId,
    });

    await connection.close();

    if (results.isNotEmpty) {
      return results[0][0] == 1;
    }

    return false;
  }
}

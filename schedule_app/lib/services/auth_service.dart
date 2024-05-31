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

  int? currentUserId;
  bool? isAdmin;

  Future<bool> login(String username, String password) async {
    final connection = createConnection();
    await connection.open();

    final passwordHash = md5.convert(utf8.encode(password)).toString();

    var result = await connection.query('''
      SELECT cnt_id, cnt_type FROM client WHERE cnt_login = @username AND cnt_pass = @password
    ''', substitutionValues: {
      'username': username,
      'password': passwordHash,
    });

    if (result.isNotEmpty) {
      currentUserId = result.first[0];
      isAdmin = result.first[1] == 1;
      notifyListeners();
      await connection.close();
      return true;
    } else {
      await connection.close();
      return false;
    }
  }

  Future<void> logout() async {
    currentUserId = null;
    isAdmin = false;
    notifyListeners();
  }
}

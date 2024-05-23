import 'package:postgres/postgres.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService extends ChangeNotifier {
  bool isConnected = false;

  late PostgreSQLConnection _connection;

  AuthService() {
    _connectToDatabase();
  }

  Future<void> _connectToDatabase() async {
    _connection = PostgreSQLConnection(
      'localhost',
      5432,
      'schedule_db',
      username: 'postgres',
      password: "'",
    );
    await _connection.open();
    isConnected = true;
  }

  int? _currentUserId;
  int? get currentUserId => _currentUserId;

  Future<bool> login(String username, String password) async {
    if (!isConnected) {
      await _connectToDatabase();
    }
    final passwordHash = md5.convert(utf8.encode(password)).toString();
    List<List<dynamic>> results = await _connection.query('''
      SELECT cnt_id FROM client WHERE cnt_login = @username AND cnt_pass = @passwordHash
    ''', substitutionValues: {
      'username': username,
      'passwordHash': passwordHash,
    });

    if (results.isNotEmpty) {
      _currentUserId = results[0][0];

      return true;
    }

    return false;
  }

  Future<bool> isAdmin() async {
    List<List<dynamic>> results = await _connection.query('''
      SELECT cnt_type FROM client WHERE cnt_id = @currentUserId
    ''', substitutionValues: {
      'currentUserId': _currentUserId,
    });

    if (results.isNotEmpty) {
      return results[0][0] == 1;
    }

    return false;
  }
}

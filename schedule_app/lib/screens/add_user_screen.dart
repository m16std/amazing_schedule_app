import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:schedule_app/services/auth_service.dart';

class AddUserScreen extends StatefulWidget {
  @override
  _AddUserScreenState createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _surname = '';
  String _login = '';
  String _password = '';
  int _type = 0;

  Future<void> _addUser() async {
    final authService = AuthService();
    PostgreSQLConnection connection = authService.createConnection();
    await connection.open();
    await connection.query('''
      INSERT INTO client (cnt_name, cnt_surname, cnt_login, cnt_pass, cnt_type)
      VALUES (@name, @surname, @login, crypt(@password, gen_salt('bf')), @type)
    ''', substitutionValues: {
      'name': _name,
      'surname': _surname,
      'login': _login,
      'password': _password,
      'type': _type,
    });
    await connection.close();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add User')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Name'),
                onChanged: (value) => _name = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Surname'),
                onChanged: (value) => _surname = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Login'),
                onChanged: (value) => _login = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                onChanged: (value) => _password = value,
                obscureText: true,
              ),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Type'),
                value: _type,
                items: [
                  DropdownMenuItem(value: 0, child: Text('User')),
                  DropdownMenuItem(value: 1, child: Text('Admin')),
                ],
                onChanged: (value) => _type = value!,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addUser,
                child: Text('Add User'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

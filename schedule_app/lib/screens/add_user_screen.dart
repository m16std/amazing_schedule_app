import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:schedule_app/services/auth_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AddUserScreen extends StatefulWidget {
  @override
  _AddUserScreenState createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  List<DropdownMenuItem<int>> _groupItems = [];
  List? groups;

  int? selectedGroup;

  @override
  void initState() {
    super.initState();
    _fetchGroupsAndSemesters();
  }

  Future<void> _fetchGroupsAndSemesters() async {
    final authService = AuthService();
    PostgreSQLConnection connection = authService.createConnection();
    await connection.open();

    List<List<dynamic>> groupResults = await connection.query('''
      SELECT g.grp_id, g.grp_name 
      FROM groups g 
    ''');

    List<DropdownMenuItem<int>> groupItems = groupResults.map((group) {
      return DropdownMenuItem<int>(
        value: group[0],
        child: Text(group[1]),
      );
    }).toList();

    groups = groupResults.map((group) {
      return group[1];
    }).toList();

    int? defaultGroup = groupItems.isNotEmpty ? groupItems.first.value : null;

    setState(() {
      _groupItems = groupItems;
      selectedGroup = defaultGroup;
    });
    await connection.close();
  }

  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _surname = '';
  String _patronymic = '';
  String _bd = '';
  String _login = '';
  String _password = '';
  bool _isAdmin = false;
  String _groupName = '';

  Future<void> _addUser() async {
    final authService = AuthService();
    PostgreSQLConnection connection = authService.createConnection();
    await connection.open();

    try {
      // Проверка существования пользователя с таким же логином
      final passwordHash = md5.convert(utf8.encode(_password)).toString();

      var userCheck = await connection.query('''
      SELECT cnt_id, cnt_type FROM client WHERE cnt_login = @username AND cnt_pass = @password
    ''', substitutionValues: {
        'username': _login,
        'password': passwordHash,
      });
      if (userCheck.isNotEmpty) {
        await connection.close();
        throw Exception('Пользователь с таким логином уже существует.');
      }

      // Проверка существования группы с таким названием
      var groupCheck = await connection.query('''
        SELECT grp_id FROM groups WHERE grp_name = @groupName
      ''', substitutionValues: {
        'groupName': _groupName,
      });
      if (groupCheck.isEmpty) {
        await connection.close();
        throw Exception('Группы с таким названием не существует.');
      }

      // Добавление пользователя
      var userResult = await connection.query('''
      INSERT INTO client (cnt_name, cnt_surname, cnt_patronymic, cnt_bd, cnt_login, cnt_pass, cnt_type)
      VALUES (@name, @surname, @patronymic, @bd, @login, @password, @isAdmin)
    ''', substitutionValues: {
        'name': _name,
        'surname': _surname,
        'patronymic': _patronymic,
        'bd': _bd,
        'login': _login,
        'password': passwordHash,
        'isAdmin': _isAdmin ? 1 : 0,
      });

      if (userResult.isNotEmpty) {
        int userId = userResult.first[0];

        // Получение идентификатора группы
        var groupResult = await connection.query('''
          SELECT grp_id FROM groups WHERE grp_name = @groupName
        ''', substitutionValues: {
          'groupName': _groupName,
        });

        if (groupResult.isNotEmpty) {
          int groupId = groupResult.first[0];

          // Добавление записи в таблицу cnt_grp
          await connection.query('''
            INSERT INTO cnt_grp (cnt_id, grp_id)
            VALUES (@userId, @groupId)
          ''', substitutionValues: {
            'userId': userId,
            'groupId': groupId,
          });
        }
      }

      await connection.close();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Пользователь добавлен')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Не удалось добавить. $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Добавить пользователя'),
          automaticallyImplyLeading: false,
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ),
          ]),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Имя'),
                onChanged: (value) => _name = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Фамилия'),
                onChanged: (value) => _surname = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Отчество'),
                onChanged: (value) => _patronymic = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Дата рождения'),
                onChanged: (value) => _bd = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Логин'),
                onChanged: (value) => _login = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Пароль'),
                onChanged: (value) => _password = value,
                obscureText: true,
              ),
              Row(children: [
                const Text('Группа'),
                Expanded(
                  child: Container(),
                ),
                DropdownButton<int>(
                  value: selectedGroup,
                  items: _groupItems,
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() {
                        selectedGroup = value;
                        _groupName = groups![value - 1];
                      });
                    }
                  },
                ),
              ]),
              Divider(),
              CheckboxListTile(
                title: Text('Явл. админом'),
                value: _isAdmin,
                onChanged: (value) {
                  setState(() {
                    _isAdmin = value ?? false;
                  });
                },
              ),
              Divider(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addUser,
                child: Text('Добавить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/*
class AddUserScreen extends StatefulWidget {
  @override
  _AddUserScreenState createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _surname = '';
  String _patronymic = '';
  String _bd = '';
  String _login = '';
  String _password = '';

  int _type = 0;

  Future<void> _addUser() async {
    final authService = AuthService();
    PostgreSQLConnection connection = authService.createConnection();
    await connection.open();
    await connection.query('''
      INSERT INTO client (cnt_name, cnt_surname, cnt_patronymic, cnt_bd, cnt_login, cnt_pass, cnt_type)
      VALUES (@name, @surname, @patronymic, @bd, @login, crypt(@password, gen_salt('bf')), @type)
    ''', substitutionValues: {
      'name': _name,
      'surname': _surname,
      'patronymic': _patronymic,
      'bd': _bd,
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
      appBar: AppBar(title: Text('Добавить пользователя'), actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ),
      ]),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Имя'),
                onChanged: (value) => _name = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Фамилия'),
                onChanged: (value) => _surname = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Отчество'),
                onChanged: (value) => _patronymic = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Дата рождения'),
                onChanged: (value) => _bd = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Логин'),
                onChanged: (value) => _login = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Пароль'),
                onChanged: (value) => _password = value,
                obscureText: true,
              ),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Тип'),
                value: _type,
                items: [
                  DropdownMenuItem(value: 0, child: Text('Пользователь')),
                  DropdownMenuItem(value: 1, child: Text('Администратор')),
                ],
                onChanged: (value) => _type = value!,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addUser,
                child: Text('Добавить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:provider/provider.dart';
import 'package:schedule_app/services/auth_service.dart';

class AddMessageScreen extends StatefulWidget {
  @override
  _AddMessageScreenState createState() => _AddMessageScreenState();
}

class _AddMessageScreenState extends State<AddMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  String _messageText = '';
  String _groupName = '';
  int _semesterNumber = 1;

  List<DropdownMenuItem<int>> _groupItems = [];
  List? groups;
  int? selectedGroup;
  List<DropdownMenuItem<int>> _semesterItems = [];
  int? selectedSemester;

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
    List<DropdownMenuItem<int>> semesterItems = [];

    if (defaultGroup != null) {
      semesterItems = await _fetchSemestersForGroup(defaultGroup);
    }

    setState(() {
      _groupItems = groupItems;
      selectedGroup = defaultGroup;
      _semesterItems = semesterItems;
      selectedSemester =
          semesterItems.isNotEmpty ? semesterItems.first.value : null;
    });
    await connection.close();
  }

  Future<List<DropdownMenuItem<int>>> _fetchSemestersForGroup(
      int groupId) async {
    final authService = AuthService();
    PostgreSQLConnection connection = authService.createConnection();
    await connection.open();

    List<List<dynamic>> semesterResults = await connection.query('''
      SELECT s.smt_id, s.smt_num 
      FROM semester s 
      WHERE s.grp_id = @grpId
    ''', substitutionValues: {
      'grpId': groupId,
    });

    await connection.close();

    List<DropdownMenuItem<int>> semesterItems = semesterResults.map((semester) {
      return DropdownMenuItem<int>(
        value: semester[0],
        child: Text('Семестр ${semester.last}'),
      );
    }).toList();

    return semesterItems;
  }

  Future<void> _addMessage() async {
    try {
      final authService = AuthService();
      PostgreSQLConnection connection = authService.createConnection();
      await connection.open();

      // Вызов хранимой процедуры для получения smt_id
      var result = await connection.query('''
      SELECT get_smt_id(@groupName, @semesterNumber)
    ''', substitutionValues: {
        'groupName': _groupName,
        'semesterNumber': _semesterNumber,
      });

      if (result.isNotEmpty) {
        int smtId = result.first[0];
        await connection.query('''
        INSERT INTO message (msg_text, msg_date, smt_id)
        VALUES (@messageText, NOW(), @smtId)
      ''', substitutionValues: {
          'messageText': _messageText,
          'smtId': smtId,
        });
      }

      await connection.close();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Сообщение добавлено')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Не удалось добавить. $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Добавить сообщение')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
                      List<DropdownMenuItem<int>> semesterItems =
                          await _fetchSemestersForGroup(value);
                      setState(() {
                        _semesterItems = semesterItems;
                        selectedSemester = semesterItems.isNotEmpty
                            ? semesterItems[0].value
                            : null;
                      });
                    }
                  },
                ),
              ]),
              Divider(),
              Row(children: [
                const Text('Семестр'),
                Expanded(
                  child: Container(),
                ),
                DropdownButton<int>(
                  value: selectedSemester,
                  items: _semesterItems,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedSemester = value;
                        _semesterNumber = selectedSemester!;
                      });
                    }
                  },
                ),
              ]),
              Divider(),
              TextFormField(
                decoration: InputDecoration(labelText: 'Текст сообщения'),
                onChanged: (value) => _messageText = value,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addMessage,
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
import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:schedule_app/services/auth_service.dart';

class AddMessageScreen extends StatefulWidget {
  @override
  _AddMessageScreenState createState() => _AddMessageScreenState();
}

class _AddMessageScreenState extends State<AddMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  String _messageText = '';

  Future<void> _addMessage() async {
    final authService = AuthService();
    PostgreSQLConnection connection = authService.createConnection();
    await connection.open();
    await connection.query('''
      INSERT INTO message (msg_text, msg_date)
      VALUES (@messageText, NOW())
    ''', substitutionValues: {
      'messageText': _messageText,
    });
    await connection.close();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Добавить сообщение')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Текст'),
                onChanged: (value) => _messageText = value,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addMessage,
                child: Text('Сообщение'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
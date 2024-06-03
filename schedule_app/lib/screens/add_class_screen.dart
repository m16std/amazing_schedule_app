import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:provider/provider.dart';
import 'package:schedule_app/services/auth_service.dart';

class AddClassScreen extends StatefulWidget {
  @override
  _AddClassScreenState createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  List<DropdownMenuItem<int>> _groupItems = [];
  List? groups;
  List<DropdownMenuItem<int>> _semesterItems = [];
  int? selectedGroup;
  int? selectedSemester;
  final _formKey = GlobalKey<FormState>();
  String _subject = '';
  String _teacher = '';
  String _room = '';
  int _classType = 1;
  int _classNum = 1;
  int _day = 0;
  int _periodicity = 3;
  int _week = 0;
  String _groupName = '';
  int _semesterNumber = 1;

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

  Future<void> _addClass() async {
    try {
      final authService = AuthService();
      PostgreSQLConnection connection = authService.createConnection();
      await connection.open();

      await connection.query('''
        INSERT INTO class (smt_id, cls_subject, cls_teacher, cls_room, cls_type, cls_num, cls_day, cls_week, cls_periodicity)
        VALUES (@smtId, @subject, @teacher, @room, @classType, @classNum, @day, @week, @periodicity)
      ''', substitutionValues: {
        'smtId': _semesterNumber,
        'subject': _subject,
        'teacher': _teacher,
        'room': _room,
        'classType': _classType,
        'classNum': _classNum,
        'day': _day,
        'week': _week,
        'periodicity': _periodicity,
      });

      await connection.close();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Пара добавлена')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Не удалось добавить. $e')));
    }
  }

  Future<void> deleteClass() async {
    final authService = AuthService();
    PostgreSQLConnection connection = authService.createConnection();
    await connection.open();
    try {
      await connection.query(
          'CALL delete_class(@groupName, @semesterNum, @classDay, @classNum, @classType, @classWeek, @class_periodicity)',
          substitutionValues: {
            'groupName': _groupName,
            'semesterNum': _semesterNumber,
            'classDay': _day,
            'classNum': _classNum,
            'classType': _classType,
            'classWeek': _week,
            'class_periodicity': _periodicity,
          });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Не удалось добавить. $e')));
    } finally {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Добавлено')));
      await connection.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить пару')),
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
              const Divider(),
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
              const Divider(),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Предмет'),
                onChanged: (value) => _subject = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Преподователь'),
                onChanged: (value) => _teacher = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Аудитория'),
                onChanged: (value) => _room = value,
              ),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Тип'),
                value: _classType,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Лекция')),
                  DropdownMenuItem(value: 2, child: Text('Практика')),
                  DropdownMenuItem(value: 3, child: Text('Лабораторная')),
                  DropdownMenuItem(value: 4, child: Text('Замена')),
                  DropdownMenuItem(value: 5, child: Text('Другое')),
                  DropdownMenuItem(value: 6, child: Text('Отмена')),
                ],
                onChanged: (value) => _classType = value!,
              ),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Время'),
                value: _classNum,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('08:00 - 09:30')),
                  DropdownMenuItem(value: 2, child: Text('09:40 - 11:10')),
                  DropdownMenuItem(value: 3, child: Text('11:20 - 12:50')),
                  DropdownMenuItem(value: 4, child: Text('13:20 - 14:50')),
                  DropdownMenuItem(value: 5, child: Text('15:00 - 16:30')),
                  DropdownMenuItem(value: 6, child: Text('16:40 - 18:10')),
                  DropdownMenuItem(value: 7, child: Text('18:35 - 20:05')),
                  DropdownMenuItem(value: 8, child: Text('20:15 - 21:45')),
                ],
                onChanged: (value) => _classNum = value!,
              ),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'День'),
                value: _day,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Понедельник')),
                  DropdownMenuItem(value: 1, child: Text('Вторник')),
                  DropdownMenuItem(value: 2, child: Text('Среда')),
                  DropdownMenuItem(value: 3, child: Text('Четверг')),
                  DropdownMenuItem(value: 4, child: Text('Пятница')),
                  DropdownMenuItem(value: 5, child: Text('Суббота')),
                ],
                onChanged: (value) => _day = value!,
              ),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Периодичность'),
                value: _periodicity,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Один раз')),
                  DropdownMenuItem(value: 1, child: Text('По белым')),
                  DropdownMenuItem(value: 2, child: Text('По зеленым')),
                  DropdownMenuItem(value: 3, child: Text('На каждой неделе')),
                ],
                onChanged: (value) => _periodicity = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Неделя'),
                onChanged: (value) => _week = int.tryParse(value) ?? 0,
              ),
              const SizedBox(height: 20),
              Container(
                height: 30,
                child: Center(
                  child: Row(
                    children: [
                      Expanded(child: (Container())),
                      ElevatedButton(
                        onPressed: _addClass,
                        child: const Text('Добавить'),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      ElevatedButton(
                        onPressed: _addClass,
                        child: const Text('Удалить'),
                      ),
                      Expanded(child: (Container()))
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*
class AddClassScreen extends StatefulWidget {
  @override
  _AddClassScreenState createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _formKey = GlobalKey<FormState>();
  String _subject = '';
  String _teacher = '';
  String _room = '';
  int _type = 1;
  int _num = 0;
  int _day = 0;
  int _periodicity = 1;
  int _week = 0;
  int _semesterId = 1;

  Future<void> _addClass() async {
    final authService = AuthService();
    PostgreSQLConnection connection = authService.createConnection();
    await connection.open();
    await connection.query('''
      INSERT INTO class (smt_id, cls_subject, cls_teacher, cls_room, cls_type, cls_num, cls_day, cls_periodicity, cls_week)
      VALUES (@semesterId, @subject, @teacher, @room, @type, @num, @day, @periodicity, @week)
    ''', substitutionValues: {
      'semesterId': _semesterId,
      'subject': _subject,
      'teacher': _teacher,
      'room': _room,
      'type': _type,
      'num': _num,
      'day': _day,
      'periodicity': _periodicity,
      'week': _week,
    });
    await connection.close();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Class')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Subject'),
                onChanged: (value) => _subject = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Teacher'),
                onChanged: (value) => _teacher = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Room'),
                onChanged: (value) => _room = value,
              ),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Type'),
                value: _type,
                items: [
                  DropdownMenuItem(value: 0, child: Text('No class')),
                  DropdownMenuItem(value: 1, child: Text('Lecture')),
                  DropdownMenuItem(value: 2, child: Text('Practice')),
                  DropdownMenuItem(value: 3, child: Text('Lab')),
                  DropdownMenuItem(value: 4, child: Text('Substitute')),
                  DropdownMenuItem(value: 5, child: Text('Other')),
                ],
                onChanged: (value) => _type = value!,
              ),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Number'),
                value: _num,
                items: List.generate(
                    8,
                    (index) =>
                        DropdownMenuItem(value: index, child: Text('$index'))),
                onChanged: (value) => _num = value!,
              ),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Day'),
                value: _day,
                items: List.generate(
                    6,
                    (index) =>
                        DropdownMenuItem(value: index, child: Text('$index'))),
                onChanged: (value) => _day = value!,
              ),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Periodicity'),
                value: _periodicity,
                items: [
                  DropdownMenuItem(
                      value: 0, child: Text('Once in a specific week')),
                  DropdownMenuItem(value: 1, child: Text('Every week')),
                  DropdownMenuItem(value: 2, child: Text('Every other week')),
                ],
                onChanged: (value) => _periodicity = value!,
              ),
              TextFormField(
                decoration: InputDecoration(
                    labelText: 'Week (if once in a specific week)'),
                onChanged: (value) => _week = int.tryParse(value) ?? 0,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Semester ID'),
                onChanged: (value) => _semesterId = int.tryParse(value) ?? 1,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addClass,
                child: Text('Add Class'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
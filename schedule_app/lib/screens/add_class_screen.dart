import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:schedule_app/services/auth_service.dart';

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

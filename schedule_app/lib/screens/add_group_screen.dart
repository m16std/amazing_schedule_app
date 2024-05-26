import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:provider/provider.dart';
import 'package:schedule_app/services/auth_service.dart';

class AddGroupScreen extends StatefulWidget {
  @override
  _AddGroupScreenState createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _groupName = '';
  int _groupYear = 2021;
  int _groupDuration = 4;

  Future<void> _addGroup() async {
    final authService = AuthService();
    PostgreSQLConnection connection = authService.createConnection();
    await connection.open();
    await connection.query('''
      INSERT INTO groups (grp_name, grp_year, grp_duration)
      VALUES (@groupName, @groupYear, @groupDuration)
    ''', substitutionValues: {
      'groupName': _groupName,
      'groupYear': _groupYear,
      'groupDuration': _groupDuration,
    });
    await connection.close();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Group')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Group Name'),
                onChanged: (value) => _groupName = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Group Year'),
                onChanged: (value) => _groupYear = int.tryParse(value) ?? 2021,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Group Duration'),
                onChanged: (value) => _groupDuration = int.tryParse(value) ?? 4,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addGroup,
                child: Text('Add Group'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

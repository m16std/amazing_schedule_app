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
      appBar: AppBar(title: Text('Add Message')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Message Text'),
                onChanged: (value) => _messageText = value,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addMessage,
                child: Text('Add Message'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

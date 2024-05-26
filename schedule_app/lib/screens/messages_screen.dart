import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedule_app/bloc/select/select_cubit.dart';
import 'package:schedule_app/screens/schedule_screen.dart';
import '../models/message.dart';
import '../services/message_service.dart';
import 'package:intl/intl.dart';

class MessagesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text('Сообщения'), automaticallyImplyLeading: false),
      body: messageList(),
      bottomNavigationBar: bottomBar(context),
    );
  }

  FutureBuilder<List<Message>> messageList() {
    return FutureBuilder<List<Message>>(
      future: MessageService().fetchMessages(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Нет доступных сообщений'));
        } else {
          final messages = snapshot.data!;
          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final formattedDate = DateFormat.yMMMMd()
                  .format(message.date); // Форматирование даты
              return Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Theme.of(context).shadowColor),
                  child: ListTile(
                    title: Text(message.text),
                    subtitle: Align(
                      alignment: Alignment.topRight,
                      child: Text(formattedDate),
                    ),
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  BottomNavigationBar bottomBar(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Дом'),
        BottomNavigationBarItem(
            icon: Icon(Icons.schedule), label: 'Расписание'),
        BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Сообщения'),
      ],
      currentIndex: 2,
      selectedItemColor: Theme.of(context).primaryColor,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacementNamed(context, '/user');
        } else if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScheduleScreen(
                selectedGroup: context.watch<SelectCubit>().state.selectedGroup,
                selectedSemester:
                    context.watch<SelectCubit>().state.selectedSemester,
                currentWeek: 0,
              ),
            ),
          );
        }
      },
    );
  }
}

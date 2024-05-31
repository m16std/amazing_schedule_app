import 'package:flutter/material.dart';
import 'package:schedule_app/screens/add_user_screen.dart';
import 'package:schedule_app/screens/add_class_screen.dart';
import 'package:schedule_app/screens/add_message_screen.dart';
import 'package:schedule_app/screens/add_group_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  static List<Widget> _pages = <Widget>[
    AddUserScreen(),
    AddClassScreen(),
    AddMessageScreen(),
    AddGroupScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _pages.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Пользователи',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.class_),
            label: 'Пары',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Сообщения',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_add),
            label: 'Группы',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Theme.of(context).disabledColor,
        showUnselectedLabels: true,
      ),
    );
  }
}

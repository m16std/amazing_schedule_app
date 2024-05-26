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
            label: 'Add User',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.class_),
            label: 'Add Class',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Add Message',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_add),
            label: 'Add Group',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.black38,
        showUnselectedLabels: true,
      ),
    );
  }
}

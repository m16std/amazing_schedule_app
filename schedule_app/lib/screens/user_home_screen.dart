import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import '../services/semester_service.dart';
import 'schedule_screen.dart';
import 'package:schedule_app/bloc/theme/theme_cubit.dart';

class UserHomeScreen extends StatefulWidget {
  @override
  _UserHomeScreenState createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedGroup = -1;
  int _selectedSemester = -1;
  List<Map<String, dynamic>> _groups = [];
  List<int> _semesters = [];
  bool _isLoadingGroups = true;
  bool _isLoadingSemesters = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUserId;
    final groupService = GroupService();
    final groups = await groupService.fetchUserGroups(userId!);
    setState(() {
      _groups = groups;
      _selectedGroup = groups.isNotEmpty ? groups[0]['grp_id'] : -1;
      _isLoadingGroups = false;
    });
    if (_selectedGroup != -1) {
      _loadSemesters(_selectedGroup);
    }
  }

  Future<void> _loadSemesters(int groupId) async {
    final semesterService = SemesterService();
    final semesters = await semesterService.fetchSemestersForGroup(groupId);
    setState(() {
      _semesters = semesters;
      _selectedSemester = semesters.isNotEmpty ? semesters[0] : -1;
      _isLoadingSemesters = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _isLoadingGroups
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildGroupAndSemesterSelectors(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Дом'),
          BottomNavigationBarItem(
              icon: Icon(Icons.schedule), label: 'Расписание'),
          BottomNavigationBarItem(
              icon: Icon(Icons.message), label: 'Сообщения'),
        ],
        currentIndex: 0,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: (index) {
          if (index == 0) {
            //Navigator.pushReplacementNamed(context, '/user');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/schedule');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/messages');
          }
        },
      ),
    );
  }

  Widget _buildGroupAndSemesterSelectors() {
    final brightness = context.watch<ThemeCubit>().state.brightness;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).shadowColor),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    const Text('Темная тема'),
                    Expanded(
                      child: Container(),
                    ),
                    Switch(
                      value: brightness == Brightness.dark,
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (bool value) {
                        context.read<ThemeCubit>().setThemeBrightness(
                            value ? Brightness.dark : Brightness.light);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).shadowColor),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Text('Група'),
                    Expanded(
                      child: Container(),
                    ),
                    DropdownButton<int>(
                      value: _selectedGroup == -1 ? null : _selectedGroup,
                      items: _groups.map((group) {
                        return DropdownMenuItem<int>(
                          value: group['grp_id'],
                          child: Text(group['grp_name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGroup = value!;
                          _isLoadingSemesters = true;
                          _loadSemesters(_selectedGroup);
                        });
                      },
                      hint: Text('Select Group'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _isLoadingSemesters
              ? CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).shadowColor),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const Text('Семестр'),
                          Expanded(
                            child: Container(),
                          ),
                          DropdownButton<int>(
                            value: _selectedSemester == -1
                                ? null
                                : _selectedSemester,
                            items: _semesters.map((semester) {
                              return DropdownMenuItem<int>(
                                value: semester,
                                child: Text('Semester $semester'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSemester = value!;
                              });
                            },
                            hint: Text('Select Semester'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}


/*
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:schedule_app/bloc/theme/theme_cubit.dart';
import '../services/auth_service.dart';
import 'schedule_screen.dart';

class UserHomeScreen extends StatefulWidget {
  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedGroup = 0;
  int _selectedSemester = 0;

  @override
  Widget build(BuildContext context) {
    final brightness = context.watch<ThemeCubit>().state.brightness;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Домашнаяя страница'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthService>().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Color.fromARGB(38, 255, 255, 255)),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  const Text('Темная тема'),
                  Expanded(
                    child: Container(),
                  ),
                  Switch(
                    value: brightness == Brightness.dark,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (bool value) {
                      context.read<ThemeCubit>().setThemeBrightness(
                          value ? Brightness.dark : Brightness.light);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildGroupAndSemesterSelectors(),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Дом'),
          BottomNavigationBarItem(
              icon: Icon(Icons.schedule), label: 'Расписание'),
          BottomNavigationBarItem(
              icon: Icon(Icons.message), label: 'Сообщения'),
        ],
        currentIndex: 0,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: (index) {
          if (index == 0) {
            //Navigator.pushReplacementNamed(context, '/user');
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScheduleScreen(
                  selectedGroup: _selectedGroup,
                  selectedSemester: _selectedSemester,
                ),
              ),
            );
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/messages');
          }
        },
      ),
    );
  }

  Widget _buildGroupAndSemesterSelectors() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          DropdownButton<int>(
            value: _selectedGroup,
            items: _buildGroupDropdownItems(),
            onChanged: (value) {
              setState(() {
                _selectedGroup = value!;
              });
            },
            hint: Text('Select Group'),
          ),
          DropdownButton<int>(
            value: _selectedSemester,
            items: _buildSemesterDropdownItems(),
            onChanged: (value) {
              setState(() {
                _selectedSemester = value!;
              });
            },
            hint: Text('Select Semester'),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<int>> _buildGroupDropdownItems() {
    // Замените на реальный список групп, полученных из базы данных
    List<int> groupIds = [0, 1, 2]; // Это пример, замените на реальные данные
    return groupIds.map((id) {
      return DropdownMenuItem<int>(
        value: id,
        child: Text('Group $id'),
      );
    }).toList();
  }

  List<DropdownMenuItem<int>> _buildSemesterDropdownItems() {
    // Замените на реальный список семестров, полученных из базы данных
    List<int> semesterIds = [
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      7
    ]; // Это пример, замените на реальные данные
    return semesterIds.map((id) {
      return DropdownMenuItem<int>(
        value: id,
        child: Text('Semester $id'),
      );
    }).toList();
  }
}

*/
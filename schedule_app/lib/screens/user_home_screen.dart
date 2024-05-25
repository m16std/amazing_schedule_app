import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/semester.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import '../services/semester_service.dart';
import 'schedule_screen.dart';
import 'package:schedule_app/bloc/theme/theme_cubit.dart';
import 'package:schedule_app/bloc/select/select_cubit.dart';
import 'package:postgres/postgres.dart';

class UserHomeScreen extends StatefulWidget {
  @override
  _UserHomeScreenState createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  List<DropdownMenuItem<int>> _groupItems = [];
  List<DropdownMenuItem<int>> _semesterItems = [];
  int? selectedGroup;
  int? selectedSemester;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGroupsAndSemesters();
  }

  Future<void> _fetchGroupsAndSemesters() async {
    final _authService = Provider.of<AuthService>(context, listen: false);
    final authService = AuthService();
    PostgreSQLConnection connection = authService.createConnection();
    await connection.open();

    // Fetch groups
    List<List<dynamic>> groupResults = await connection.query('''
      SELECT g.grp_id, g.grp_name 
      FROM groups g 
      INNER JOIN cnt_grp cg ON g.grp_id = cg.grp_id 
      WHERE cg.cnt_id = @cntId
    ''', substitutionValues: {
      'cntId': _authService.currentUserId,
    });

    // Populate group items
    List<DropdownMenuItem<int>> groupItems = groupResults.map((group) {
      return DropdownMenuItem<int>(
        value: group[0],
        child: Text(group[1]),
      );
    }).toList();

    // Select the first group by default
    int? defaultGroup = groupItems.isNotEmpty ? groupItems.last.value : null;

    // Fetch semesters for the default group
    List<DropdownMenuItem<int>> semesterItems = [];
    if (defaultGroup != null) {
      semesterItems = await _fetchSemestersForGroup(defaultGroup);
    }

    setState(() {
      _groupItems = groupItems;
      selectedGroup = defaultGroup;
      _semesterItems = semesterItems;
      selectedSemester =
          semesterItems.isNotEmpty ? semesterItems.last.value : null;
      isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    final brightness = context.watch<ThemeCubit>().state.brightness;

    if (context.watch<SelectCubit>().state.selectedGroup != -1) {
      selectedGroup = context.watch<SelectCubit>().state.selectedGroup;
    }

    if (context.watch<SelectCubit>().state.selectedSemester != -1) {
      selectedSemester = context.watch<SelectCubit>().state.selectedSemester;
    }

    return Scaffold(
      appBar: AppBar(
          title: Text('Домашняя страница'), automaticallyImplyLeading: false),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ThemeSelector(context, brightness),
                  GroupSelector(context),
                  SemesterSelector(context)
                ],
              ),
            ),
      bottomNavigationBar: bottomBar(context),
    );
  }

  Padding GroupSelector(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).shadowColor),
            child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(children: [
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
                          isLoading = true;
                        });

                        List<DropdownMenuItem<int>> semesterItems =
                            await _fetchSemestersForGroup(value);

                        setState(() {
                          _semesterItems = semesterItems;
                          selectedSemester = semesterItems.isNotEmpty
                              ? semesterItems[0].value
                              : null;
                          isLoading = false;
                        });
                        context.read<SelectCubit>().setSelect(
                            selectedSemester ?? -1, selectedGroup ?? -1);
                      }
                    },
                  ),
                ]))));
  }

  Padding SemesterSelector(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).shadowColor),
            child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(children: [
                  const Text('Семестр'),
                  Expanded(
                    child: Container(),
                  ),
                  DropdownButton<int>(
                    value: selectedSemester,
                    items: _semesterItems,
                    onChanged: (value) {
                      setState(() {
                        selectedSemester = value;
                      });
                      context.read<SelectCubit>().setSelect(
                          selectedSemester ?? -1, selectedGroup ?? -1);
                    },
                  ),
                ]))));
  }

  Padding ThemeSelector(BuildContext context, Brightness brightness) {
    return Padding(
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
                selectedGroup: selectedGroup ?? -1,
                selectedSemester: selectedSemester ?? -1,
              ),
            ),
          );
        } else if (index == 2) {
          Navigator.pushReplacementNamed(context, '/messages');
        }
      },
    );
  }
/*
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
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
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                groupAndSemesterSelectors(),
              ],
            ),
      bottomNavigationBar: bottomBar(context),
    );
  }



  Widget groupAndSemesterSelectors() {
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
                      hint: const Text('Выберите группу'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _isLoadingSemesters
              ? const CircularProgressIndicator()
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
                                child: Text('Семестр $semester'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSemester = value!;
                              });
                            },
                            hint: const Text('Выберите семестр'),
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
  */
}

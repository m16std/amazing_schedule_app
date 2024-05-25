import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:postgres/postgres.dart';
import '../bloc/select/select_cubit.dart';
import '../models/class_model.dart';
import '../services/auth_service.dart';
import '../services/class_service.dart';

class ScheduleScreen extends StatefulWidget {
  final int selectedGroup;
  final int selectedSemester;

  ScheduleScreen({required this.selectedGroup, required this.selectedSemester});

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _currentWeek = 0;
  late Future<List<Class>> _classesFuture;

  Future<List<Class>> _fetchClasses() async {
    final service = ClassService();
    return service.fetchClasses(widget.selectedSemester, _currentWeek);
  }

  List<List<Map<String, dynamic>>> whiteWeekSchedule = [];
  List<List<Map<String, dynamic>>> greenWeekSchedule = [];
  bool isLoading = true;
  int currentWeek = 1;

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    final authService = AuthService();
    PostgreSQLConnection connection = authService.createConnection();
    await connection.open();

    // Получение расписания для белой и зеленой недели
    List<List<Map<String, dynamic>>> fetchedWhiteWeekSchedule =
        List.generate(6, (_) => []);
    List<List<Map<String, dynamic>>> fetchedGreenWeekSchedule =
        List.generate(6, (_) => []);

    List<List<dynamic>> scheduleResults = await connection.query('''
      SELECT cls_id, cls_subject, cls_teacher, cls_room, cls_type, cls_num, cls_day, cls_periodicity, cls_week
      FROM class 
      WHERE smt_id = @smtId
    ''', substitutionValues: {
      'smtId': widget.selectedSemester,
    });

    for (var row in scheduleResults) {
      Map<String, dynamic> classInfo = {
        'subject': row[1],
        'teacher': row[2],
        'room': row[3],
        'type': row[4],
        'num': row[5],
        'day': row[6],
      };

      if (row[7] == 3 ||
          (row[7] == 1) ||
          (row[7] == 0 && row[8] == currentWeek - 1)) {
        fetchedWhiteWeekSchedule[row[6]].add(classInfo);
      }
      if (row[7] == 3 ||
          (row[7] == 2) ||
          (row[7] == 0 && row[8] == currentWeek)) {
        fetchedGreenWeekSchedule[row[6]].add(classInfo);
      }
    }

    setState(() {
      whiteWeekSchedule = fetchedWhiteWeekSchedule;
      greenWeekSchedule = fetchedGreenWeekSchedule;
      isLoading = false;
    });

    await connection.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text('Расписание'), automaticallyImplyLeading: false),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    _buildControls(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text('Белая неделя',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              _buildWeekColumn(whiteWeekSchedule),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text('Зеленая неделя',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              _buildWeekColumn(greenWeekSchedule),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: bottomBar(context),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _currentWeek = (_currentWeek - 2).clamp(0, 14);
              });
            },
          ),
          Text('Недели ${_currentWeek + 1} - ${_currentWeek + 2}',
              style: TextStyle(fontSize: 16)),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () {
              setState(() {
                _currentWeek = (_currentWeek + 2).clamp(0, 14);
              });
            },
          ),
        ],
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
      currentIndex: 1,
      selectedItemColor: Theme.of(context).primaryColor,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacementNamed(context, '/user');
        } else if (index == 1) {
          //Navigator.pushReplacementNamed(context, '/schedule');
        } else if (index == 2) {
          Navigator.pushReplacementNamed(context, '/messages');
        }
      },
    );
  }

  Widget _buildWeekColumn(List<List<Map<String, dynamic>>> weekSchedule) {
    return Column(
      children: List.generate(6, (dayIndex) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getDayName(dayIndex),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            ...weekSchedule[dayIndex].map((classInfo) {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Theme.of(context).shadowColor),
                  child: ListTile(
                    title: Text(
                        '${classInfo['subject']} (${_getClassTypeName(classInfo['type'])})'),
                    subtitle: Text(
                        '${classInfo['teacher']}\nАуд: ${classInfo['room']}'),
                    trailing: Text(_getClassTime(classInfo['num'])),
                  ),
                ),
              );
            }).toList(),
            Divider(),
          ],
        );
      }),
    );
  }

  String _getDayName(int dayIndex) {
    switch (dayIndex) {
      case 0:
        return 'Понедельник';
      case 1:
        return 'Вторник';
      case 2:
        return 'Среда';
      case 3:
        return 'Четверг';
      case 4:
        return 'Пятница';
      case 5:
        return 'Суббота';
      default:
        return '';
    }
  }

  String _getClassTime(int classNum) {
    switch (classNum) {
      case 0:
        return '08:00 - 09:30';
      case 1:
        return '09:40 - 11:10';
      case 2:
        return '11:20 - 12:50';
      case 3:
        return '13:20 - 14:50';
      case 4:
        return '15:00 - 16:30';
      case 5:
        return '16:40 - 18:10';
      case 6:
        return '18:35 - 20:05';
      case 7:
        return '20:15 - 21:45';
      default:
        return '';
    }
  }

  String _getClassTypeName(int classType) {
    switch (classType) {
      case 1:
        return 'Лек';
      case 2:
        return 'Пр';
      case 3:
        return 'Лаб';
      case 4:
        return 'Замена';
      case 5:
        return 'Другое';
      default:
        return 'Окно';
    }
  }
}




/*






      bottomNavigationBar: bottomBar(context),

  BottomNavigationBar bottomBar(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Дом'),
        BottomNavigationBarItem(
            icon: Icon(Icons.schedule), label: 'Расписание'),
        BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Сообщения'),
      ],
      currentIndex: 1,
      selectedItemColor: Theme.of(context).primaryColor,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacementNamed(context, '/user');
        } else if (index == 1) {
          //Navigator.pushReplacementNamed(context, '/schedule');
        } else if (index == 2) {
          Navigator.pushReplacementNamed(context, '/messages');
        }
      },
    );
  }





class ScheduleScreen extends StatelessWidget {
  Future<List<Map<String, dynamic>>> _fetchSchedule() async {
    final db = await DBService().database;
    return await db.query('schedule');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Schedule')),
      body: FutureBuilder(
        future: _fetchSchedule(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final schedule = snapshot.data as List<Map<String, dynamic>>;
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(// a dirty trick to make the DataTable fit width
                  children: <Widget>[
                Expanded(
                    child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          columns: const [
                            DataColumn(
                              label: Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [Text("Белая неделя")],
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [Text("Зеленая неделя")],
                                ),
                              ),
                            ),
                          ],
                          rows: List<DataRow>.generate(
                            6,
                            (index) {
                              return DataRow(cells: [
                                DataCell(Text(schedule
                                    .where((s) =>
                                        s['weekType'] == 0 && s['day'] == index)
                                    .map((s) => s['subject'])
                                    .join('\n'))),
                                DataCell(Text(schedule
                                    .where((s) =>
                                        s['weekType'] == 1 && s['day'] == index)
                                    .map((s) => s['subject'])
                                    .join('\n'))),
                              ]);
                            },
                          ),
                        )))
              ]),
            );
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Дом'),
          BottomNavigationBarItem(
              icon: Icon(Icons.schedule), label: 'Расписание'),
          BottomNavigationBarItem(
              icon: Icon(Icons.message), label: 'Сообщения'),
        ],
        currentIndex: 1,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/user');
          } else if (index == 1) {
            //Navigator.pushReplacementNamed(context, '/schedule');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/messages');
          }
        },
      ),
    );
  }
}
*/
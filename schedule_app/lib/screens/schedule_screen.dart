import 'package:flutter/material.dart';
import '../models/class_model.dart';
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

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    _classesFuture = _fetchClasses();
  }

  Future<List<Class>> _fetchClasses() async {
    final service = ClassService();
    return service.fetchClasses(widget.selectedSemester, _currentWeek);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Schedule')),
      body: Column(
        children: [
          _buildWeekNavigation(),
          _buildSchedule(),
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

  Widget _buildWeekNavigation() {
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
                _loadInitialData();
              });
            },
          ),
          Text('Weeks ${_currentWeek + 1} - ${_currentWeek + 2}'),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () {
              setState(() {
                _currentWeek = (_currentWeek + 2).clamp(0, 14);
                _loadInitialData();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSchedule() {
    return Expanded(
      child: FutureBuilder<List<Class>>(
        future: _classesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No classes available'));
          } else {
            final classes = snapshot.data!;
            return _buildClassTable(classes);
          }
        },
      ),
    );
  }

  Widget _buildClassTable(List<Class> classes) {
    final schedule =
        List.generate(6, (day) => List.generate(8, (num) => null as Class?));

    for (var cls in classes) {
      if (cls.day < 6 && cls.num < 8) {
        if (schedule[cls.day][cls.num] == null ||
            schedule[cls.day][cls.num]!.type < cls.type) {
          schedule[cls.day][cls.num] = cls;
        }
      }
    }

    return Table(
      children: List.generate(6, (day) {
        return TableRow(
          children: List.generate(8, (num) {
            final cls = schedule[day][num];
            return TableCell(
              child: cls == null
                  ? Container(height: 50, color: Colors.grey[200])
                  : Container(
                      height: 50,
                      padding: EdgeInsets.all(8.0),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cls.subject,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(cls.teacher),
                          Text(cls.room),
                          Text(_getClassType(cls.type)),
                        ],
                      ),
                    ),
            );
          }),
        );
      }),
    );
  }

  String _getClassType(int type) {
    switch (type) {
      case 1:
        return 'Lecture';
      case 2:
        return 'Practice';
      case 3:
        return 'Lab';
      case 4:
        return 'Replacement';
      case 5:
        return 'Other';
      default:
        return '';
    }
  }
}




/*
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
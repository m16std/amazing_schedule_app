import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_saver/flutter_image_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:postgres/postgres.dart';
import 'package:screenshot/screenshot.dart';
import '../bloc/select/select_cubit.dart';

import '../services/auth_service.dart';

import 'package:share/share.dart';

class ScheduleScreen extends StatefulWidget {
  final int selectedGroup;
  final int selectedSemester;
  final int currentWeek;

  ScheduleScreen({
    required this.selectedGroup,
    required this.selectedSemester,
    required this.currentWeek,
  });

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<List<Map<String, dynamic>>> whiteWeekSchedule = [];
  List<List<Map<String, dynamic>>> greenWeekSchedule = [];
  bool isLoading = true;

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
          (row[7] == 0 && row[8] == widget.currentWeek - 1)) {
        fetchedWhiteWeekSchedule[row[6]].add(classInfo);
      }
      if (row[7] == 3 ||
          (row[7] == 2) ||
          (row[7] == 0 && row[8] == widget.currentWeek)) {
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

  Uint8List? _imageFile;
  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: topBar(),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : scheduleWidget(),
      bottomNavigationBar: bottomBar(context),
    );
  }

  SingleChildScrollView scheduleWidget() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Screenshot(
          controller: screenshotController,
          child: Column(
            children: [
              _buildControls(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('Белая неделя',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
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
                                fontSize: 16, fontWeight: FontWeight.bold)),
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
    );
  }

  AppBar topBar() {
    return AppBar(
        title: Text('Расписание'),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Поделиться',
              onPressed: () {
                screenshotController
                    .capture(delay: Duration(milliseconds: 10))
                    .then((capturedImage) async {
                  await saveImage(capturedImage!, 'image.png');
                }).catchError((onError) {
                  print(onError);
                });
              },
            ),
          ),
        ]);
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
              Navigator.pop(context); // pop current page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScheduleScreen(
                      selectedGroup:
                          context.watch<SelectCubit>().state.selectedGroup,
                      selectedSemester:
                          context.watch<SelectCubit>().state.selectedSemester,
                      currentWeek: (widget.currentWeek - 2).clamp(0, 14)),
                ),
              );
            },
          ),
          Text('Недели ${widget.currentWeek + 1} - ${widget.currentWeek + 2}',
              style: TextStyle(fontSize: 16)),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () {
              Navigator.pop(context); // pop current page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScheduleScreen(
                      selectedGroup:
                          context.watch<SelectCubit>().state.selectedGroup,
                      selectedSemester:
                          context.watch<SelectCubit>().state.selectedSemester,
                      currentWeek: (widget.currentWeek + 2).clamp(0, 14)),
                ),
              );
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

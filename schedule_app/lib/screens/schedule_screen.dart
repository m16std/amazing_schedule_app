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
      ORDER BY cls_day, cls_num, cls_type DESC
    ''', substitutionValues: {
      'smtId': widget.selectedSemester,
    });

    List<List<int>> specials = [
      [-1, -1, -1, -1, -1]
    ];

    for (var row in scheduleResults) {
      Map<String, dynamic> classInfo = {
        'subject': row[1],
        'teacher': row[2],
        'room': row[3],
        'type': row[4],
        'num': row[5],
        'day': row[6],
      };

      if (specials.last[1] == row[5] && specials.last[2] == row[6]) {
        //если специальная пара заменила текущую пару
        if (specials.last[4] % 2 == 1) {
          //и специальная пара была на белой неделе
          if (row[7] == 3 ||
              (row[7] == 2) ||
              (row[7] == 0 && row[8] == widget.currentWeek + 2)) {
            fetchedGreenWeekSchedule[row[6]].add(classInfo);
          }
        } else {
          //и специальная пара была на зеленой неделе
          if (row[7] == 3 ||
              (row[7] == 1) ||
              (row[7] == 0 && row[8] == widget.currentWeek + 1)) {
            fetchedWhiteWeekSchedule[row[6]].add(classInfo);
          }
        }
      } else {
        if (row[7] == 3 ||
            (row[7] == 1) ||
            (row[7] == 0 && row[8] == widget.currentWeek + 1)) {
          fetchedWhiteWeekSchedule[row[6]].add(classInfo);
          if (row[4] >= 4) {
            specials.add([row[4], row[5], row[6], row[7], row[8]]);
          }
        }
        if (row[7] == 3 ||
            (row[7] == 2) ||
            (row[7] == 0 && row[8] == widget.currentWeek + 2)) {
          fetchedGreenWeekSchedule[row[6]].add(classInfo);
          if (row[4] >= 4) {
            specials.add([row[4], row[5], row[6], row[7], row[8]]);
          }
        }
      }
    }

    setState(() {
      whiteWeekSchedule = fetchedWhiteWeekSchedule;
      greenWeekSchedule = fetchedGreenWeekSchedule;
      isLoading = false;
    });

    await connection.close();
  }

  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: topBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : scheduleWidget(),
      bottomNavigationBar: bottomBar(context),
    );
  }

  SingleChildScrollView scheduleWidget() {
    return SingleChildScrollView(
      child: Screenshot(
        controller: screenshotController,
        child: Container(
          decoration: BoxDecoration(color: Theme.of(context).canvasColor),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                _buildControls(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildWeekColumn(whiteWeekSchedule, 0),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          _buildWeekColumn(greenWeekSchedule, 1),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekColumn(
      List<List<Map<String, dynamic>>> weekSchedule, int type) {
    return Column(
      children: List.generate(6, (dayIndex) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getDayName(dayIndex),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            ...weekSchedule[dayIndex].map((classInfo) {
              return Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: classInfo['type'] == 4
                          ? const Color.fromARGB(58, 160, 148, 39)
                          : classInfo['type'] == 5
                              ? const Color.fromARGB(57, 150, 59, 255)
                              : classInfo['type'] == 6
                                  ? const Color.fromARGB(57, 255, 59, 59)
                                  : type == 0
                                      ? Theme.of(context).shadowColor
                                      : const Color.fromARGB(59, 59, 160, 39)),
                  child: ListTile(
                    title: Text(
                      '${classInfo['subject']} ${_getClassTypeName(classInfo['type'])}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    subtitle: Text(
                      '${classInfo['teacher'] ?? ''}\nАуд: ${classInfo['room']}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Text(
                      classInfo['type'] == 6
                          ? 'ОТМЕНА\n${_getClassTime(classInfo['num'])}'
                          : _getClassTime(classInfo['num']),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              );
            }).toList(),
            const Divider(),
          ],
        );
      }),
    );
  }

  AppBar topBar() {
    return AppBar(
        title: const Text('Расписание'),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Поделиться',
              onPressed: () {
                screenshotController
                    .capture(delay: const Duration(milliseconds: 10))
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
      padding: const EdgeInsets.all(2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
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
              style: const TextStyle(fontSize: 15)),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
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
      case 1:
        return '08:00 - 09:30';
      case 2:
        return '09:40 - 11:10';
      case 3:
        return '11:20 - 12:50';
      case 4:
        return '13:20 - 14:50';
      case 5:
        return '15:00 - 16:30';
      case 6:
        return '16:40 - 18:10';
      case 7:
        return '18:35 - 20:05';
      case 8:
        return '20:15 - 21:45';
      default:
        return '';
    }
  }

  String _getClassTypeName(int classType) {
    switch (classType) {
      case 1:
        return '(Лек)';
      case 2:
        return '(Пр)';
      case 3:
        return '(Лаб)';
      case 4:
        return '(Замена)';
      case 5:
        return '(Другое)';
      default:
        return '';
    }
  }
}

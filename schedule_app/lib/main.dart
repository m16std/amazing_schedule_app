import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:schedule_app/bloc/select/select_cubit.dart';
import 'package:schedule_app/bloc/theme/theme_cubit.dart';
import 'screens/login_screen.dart';
import 'screens/user_home_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/messages_screen.dart';
import 'services/auth_service.dart';
import 'package:desktop_window/desktop_window.dart' as window_size;
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    window_size.DesktopWindow.setWindowSize(const Size(480, 950));
  }
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => ThemeCubit()),
          BlocProvider(create: (context) => SelectCubit())
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, state) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'University Schedule',
              theme: ThemeData(
                primaryColor: const Color.fromARGB(255, 230, 148, 78),
                shadowColor: state.brightness == Brightness.dark
                    ? const Color.fromARGB(19, 255, 255, 255)
                    : const Color.fromARGB(19, 32, 32, 32),
                disabledColor: state.brightness == Brightness.light
                    ? const Color.fromARGB(80, 0, 0, 0)
                    : const Color.fromARGB(129, 255, 255, 255),
                canvasColor: state.brightness == Brightness.light
                    ? const Color.fromARGB(255, 249, 249, 255)
                    : const Color.fromARGB(255, 17, 19, 24),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blueAccent,
                  // ···
                  brightness: state.brightness == Brightness.dark
                      ? Brightness.dark
                      : Brightness.light,
                ),
              ),
              initialRoute: '/',
              routes: {
                '/': (context) => LoginScreen(),
                '/login': (context) => LoginScreen(),
                '/user': (context) => UserHomeScreen(),
                '/admin_home': (context) => AdminHomeScreen(),
                '/admin': (context) => AdminHomeScreen(),
                '/schedule': (context) => ScheduleScreen(
                      selectedGroup: 0,
                      selectedSemester: 0,
                      currentWeek: 0,
                    ),
                '/messages': (context) => MessagesScreen(),
              },
            );
          },
        ));
  }
}

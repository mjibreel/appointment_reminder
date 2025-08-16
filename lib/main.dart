import 'package:flutter/material.dart';
import 'package:appointment_reminder/pages/home_page.dart';
import 'package:appointment_reminder/pages/auth/signin_page.dart' as sign_in;
import 'package:appointment_reminder/pages/auth/signup_page.dart' as sign_up;
import 'package:appointment_reminder/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:appointment_reminder/pages/scheduling.dart';
import 'package:appointment_reminder/pages/medication_reminders.dart';
import 'package:appointment_reminder/pages/ProfileDisplayPage.dart';
import 'package:appointment_reminder/pages/ProfileSetupPage.dart';
import 'package:appointment_reminder/pages/CreateTaskPage.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<void> _initializeApp() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("Firebase initialized successfully");
      
      // Initialize other services
      tz.initializeTimeZones();      await NotificationService.init();
      await requestNotificationPermissions();
    } catch (e) {
      print("Firebase initialization error: $e");
      print(StackTrace.current);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Appointment Reminder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder(
        future: _initializeApp(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }
          
          if (snapshot.hasError) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Text('Error: ${snapshot.error}'),
                ),
              ),
            );
          }

          return const HomePage();
        },
      ),
      routes: {
        '/signin': (context) => const sign_in.SignInPage(),
        '/signup': (context) => const sign_up.SignUpPage(),
        '/home': (context) => const HomePage(),
        '/reminders': (context) => const MedicationReminderPage(),
        '/scheduling': (context) => const MedicationTrackerPage(),
        '/profile_setup': (context) => const ProfileSetupPage(),
        '/profile_display': (context) => const ProfileDisplayPage(),
        '/create_task': (context) => const CreateTaskPage(),
      },
    );
  }
}

Future<void> requestNotificationPermissions() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

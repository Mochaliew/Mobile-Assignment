import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/teacher_login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ldwrvxijjrxdffxrrknj.supabase.co',
    anonKey: 'sb_publishable_Zz4mhYdcKp_OMBeh9_rVhg_VbT5AbuC',
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Learning Teacher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B6FF5)),
        useMaterial3: true,
      ),
      home: const TeacherLogin(),
    );
  }
}
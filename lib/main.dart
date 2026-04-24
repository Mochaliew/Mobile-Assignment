import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home.dart';

// -----------------------------------------------------------------------------
// TODO(1)
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ldwrvxijjrxdffxrrknj.supabase.co',
    anonKey: 'sb_publishable_Zz4mhYdcKp_OMBeh9_rVhg_VbT5AbuC',
  );
  runApp(MainApp());
}
// -----------------------------------------------------------------------------

class MainApp extends StatelessWidget {
  MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
    );
  }
}

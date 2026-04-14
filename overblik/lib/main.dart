import 'package:flutter/material.dart';
import 'core/supabase_config.dart';
import 'core/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {

WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Emulator test'),
        ),
        body: const Center(
          child: Text(
            'It works',
            style: TextStyle(fontSize: 28),
          ),
        ),
      ),
    );
  }
}
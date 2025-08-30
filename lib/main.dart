import 'package:flutter/material.dart';
import 'screen/auth/sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://zifhcwddtatapnmmzebp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InppZmhjd2RkdGF0YXBubW16ZWJwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYzOTA5NTgsImV4cCI6MjA3MTk2Njk1OH0.8K1KY4tVsdcipB12PiTULYi3H1iDtREjhQeifyI6qio',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutridiet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SignInPage(),
       debugShowCheckedModeBanner: false, //Close the debug at right upside corner
    );
  }
}


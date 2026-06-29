import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ContactsToExcelApp());
}

class ContactsToExcelApp extends StatelessWidget {
  const ContactsToExcelApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark();
    return MaterialApp(
      title: 'ContactsXL',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: base.copyWith(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A0A1A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C6FFF),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
        dialogBackgroundColor: const Color(0xFF1E1E3F),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1E1E3F),
          contentTextStyle: GoogleFonts.poppins(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
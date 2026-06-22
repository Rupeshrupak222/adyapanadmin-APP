import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';
import 'services/auth_service.dart';
import 'services/data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Widget initialScreen = const LoginScreen();
  try {
    // Try to restore existing session
    final hasSession = await AuthService.instance.restoreSession();
    if (hasSession) {
      // Initialize backend data connection only after session is restored
      DataService.instance.initialize();

      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role');
      final displayName = prefs.getString('displayName');
      final email = prefs.getString('email');

      if (role != null && displayName != null && email != null) {
        initialScreen = MainLayout(
          role: role,
          displayName: displayName,
          email: email,
          schoolData: role == 'Principal'
              ? {
                  'name': AuthService.instance.currentUser?['school_name'] ?? '',
                  'id': AuthService.instance.currentUser?['school_id'] ?? '',
                }
              : null,
        );
      }
    }
  } catch (_) {}

  runApp(AdyapanAdminApp(initialScreen: initialScreen));
}

class AdyapanAdminApp extends StatelessWidget {
  final Widget initialScreen;
  const AdyapanAdminApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adyapan Command Center',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          primary: const Color(0xFF4F46E5),
          secondary: const Color(0xFF10B981),
          surface: Colors.white,
          background: const Color(0xFFF8FAFC),
        ),
        fontFamily: 'Inter',
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE2E8F0),
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF0F172A),
          contentTextStyle: const TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      home: initialScreen,
    );
  }
}

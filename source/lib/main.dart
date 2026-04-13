import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/hourly_wage_screen.dart';
import 'services/Ads_manager.dart';
import 'services/storage_service.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdsManager.initialize();
  await initializeDateFormatting('tr_TR', null);

  // Son seçilen ekranı oku
  final lastMode = await StorageService.loadLastScreenMode();

  runApp(PayrollApp(initialMode: lastMode));
}

class PayrollApp extends StatelessWidget {
  final String initialMode;
  const PayrollApp({super.key, required this.initialMode});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fazla Mesai Hesaplama',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),

        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF2E86DE),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFEAF3FF),
          onPrimaryContainer: Color(0xFF1B4F72),
          secondary: Color(0xFF54A0FF),
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          background: Color(0xFFF5F7FB),
          onBackground: Colors.black,
          surface: Colors.white,
          onSurface: Colors.black,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E86DE),
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E86DE),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E6ED)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2E86DE), width: 2),
          ),
        ),
      ),
      // initialMode'a göre hangi ekranın açılacağını belirle
      home: initialMode == 'hourly'
          ? const HourlyWageScreen()
          : const HomeScreen(),
    );
  }
}

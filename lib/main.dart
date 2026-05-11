import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'screens/beranda_screen.dart';
import 'services/notification_service.dart';
import 'services/firebase_schedule_service.dart';
import 'firebase_options.dart';

final themeProvider = ThemeProvider();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Jalankan aplikasi secepat mungkin agar tidak stuck di logo
  runApp(const SmartMedicineApp());

  // Lakukan inisialisasi berat di background
  _initServices();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

Future<void> _initServices() async {
  // Inisialisasi Notifikasi secara sinkron sebelum lanjut
  try {
    await NotificationService.instance.init();
    await NotificationService.instance.requestPermissions();
    debugPrint('✅ Layanan Notifikasi siap');
  } catch (e) {
    debugPrint('❌ Gagal inisialisasi notifikasi: $e');
  }

  // Inisialisasi Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseScheduleService.instance.startListening();
    debugPrint('✅ Firebase siap');
  } catch (e) {
    debugPrint('⚠️ Firebase dilewati: $e');
  }
}

class SmartMedicineApp extends StatefulWidget {
  const SmartMedicineApp({super.key});

  @override
  State<SmartMedicineApp> createState() => _SmartMedicineAppState();
}

class _SmartMedicineAppState extends State<SmartMedicineApp> {
  @override
  void initState() {
    super.initState();
    themeProvider.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Medicine Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const BerandaScreen(),
    );
  }
}

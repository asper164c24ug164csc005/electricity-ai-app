import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/bill_service.dart';
import 'screens/auth/splash_screen.dart';

void main() {
  runApp(const EnergyAssistantApp());
}

class EnergyAssistantApp extends StatelessWidget {
  const EnergyAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => BillService()
          // ..backendBaseUrl = 'http://10.0.2.2:8000' // uncomment once FastAPI backend is running
        ),
      ],
      child: MaterialApp(
        title: 'Energy Assistant',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.blue,
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

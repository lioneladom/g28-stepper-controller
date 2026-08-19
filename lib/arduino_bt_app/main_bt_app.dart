import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/arduino_bt_provider.dart';
import 'screens/main_arduino_bt_screen.dart';
import 'theme/arduino_bt_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ArduinoBtApp());
}

class ArduinoBtApp extends StatelessWidget {
  const ArduinoBtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ArduinoBtProvider(),
      child: MaterialApp(
        title: 'G28 Stepper Controller',
        debugShowCheckedModeBanner: false,
        theme: ArduinoBtTheme.darkTheme,
        home: const MainArduinoBtScreen(),
      ),
    );
  }
}

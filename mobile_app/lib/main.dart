import 'package:flutter/material.dart';
import 'screens/device_list_screen.dart';

void main() {
  runApp(const PcConnectorApp());
}

class PcConnectorApp extends StatelessWidget {
  const PcConnectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PC Connector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const DeviceListScreen(),
    );
  }
}

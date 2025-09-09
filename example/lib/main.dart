import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const FaceRecognitionDemoApp());
}

class FaceRecognitionDemoApp extends StatelessWidget {
  const FaceRecognitionDemoApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ],
        child: MaterialApp(
          title: 'Face Recognition Auth Demo',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
            ),
          ),
          home: const HomeScreen(),
          debugShowCheckedModeBanner: false,
        ),
      );
}

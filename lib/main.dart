import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:peakfinder/auth/auth.dart';
import 'package:provider/provider.dart';
import 'package:peakfinder/firebase_options.dart';
import 'package:peakfinder/services/storage.dart';
import 'package:peakfinder/services/image_path_controller.dart';
import 'package:peakfinder/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => StorageService()),
        ChangeNotifierProvider(create: (context) => ImagePathController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthPage(),
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}

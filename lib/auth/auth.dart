import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:peakfinder/auth/login_or_register.dart';
import 'package:peakfinder/screens/explore_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            return const ExplorePage();
          } else if (snapshot.hasError) {
            return const Center(child: Text('Ocorreu um erro.'));
          } else {
            return const LoginOrRegister();
          }
        },
      ),
    );
  }
}

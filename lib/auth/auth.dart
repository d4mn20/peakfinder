import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:peakfinder/auth/login_or_register.dart';
import 'package:peakfinder/pages/explore_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // user in logged in
          if (snapshot.hasData) {
            return const ExplorePage();
          }
          // user in logged out
          else {
            return const LoginOrRegister();
          }
        },
      )
    );
  }
}
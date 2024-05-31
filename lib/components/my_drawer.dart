import 'package:flutter/material.dart';
import 'package:peakfinder/auth/auth_service.dart';
import 'package:peakfinder/pages/favorites.dart';
import 'package:peakfinder/pages/explore_page.dart';
import 'package:peakfinder/pages/profile.dart';
import '../auth/login_or_register.dart';
import '../pages/settings_page.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              // app logo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50.0),
                child: DrawerHeader(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 25.0),
                      child: Image.asset(
                        'lib/images/logo.png',
                        color: Theme.of(context).colorScheme.primary,
                        height: 60,
                      ),
                    ),
                  ),
                ),
              ),

              // home list tile
              Padding(
                padding: const EdgeInsets.only(left: 25.0, top: 10),
                child: ListTile(
                  title: const Text("E X P L O R A R"),
                  leading: const Icon(Icons.map),
                  onTap: () { 
                    Navigator.pop(context);

                    // go to home page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExplorePage(),
                      ),
                    );
                  },
                ),
              ),

              // settings list tile
              Padding(
                padding: const EdgeInsets.only(left: 25.0, top: 10),
                child: ListTile(
                  title: const Text("F A V O R I T O S"),
                  leading: const Icon(Icons.favorite),
                  onTap: () {
                    // pop drawer
                    Navigator.pop(context);

                    // go to favorites page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FavoritesPage(),
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 25.0, top: 10),
                child: ListTile(
                  title: const Text("P E R F I L"),
                  leading: const Icon(Icons.account_circle),
                  onTap: () {
                    // pop drawer
                    Navigator.pop(context);

                    // go to profile page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilePage(),
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 25.0, top: 10),
                child: ListTile(
                  title: const Text("C O N F I G U R A Ç Õ E S"),
                  leading: const Icon(Icons.settings),
                  onTap: () {
                    // pop drawer
                    Navigator.pop(context);

                    // go to settings page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // logout list tile
          Padding(
            padding: const EdgeInsets.only(left: 25.0, bottom: 25),
            child: ListTile(
              title: const Text("L O G O U T"),
              leading: const Icon(Icons.logout),
              onTap: () {
                // logout and navigate to login page
                logout(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void logout(BuildContext context) async {
    // get auth service
    final auth = AuthService();
    auth.signOut();

    // Navigate to LoginOrRegister page
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginOrRegister(),
      ),
      (route) => false,
    );
  }
}
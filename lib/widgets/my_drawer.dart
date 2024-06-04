import 'package:flutter/material.dart';
import 'package:peakfinder/auth/auth_service.dart';
import 'package:peakfinder/screens/favorites_page.dart';
import 'package:peakfinder/screens/explore_page.dart';
import 'package:peakfinder/screens/profile_page.dart';
import 'package:peakfinder/screens/settings_page.dart';
import '../auth/login_or_register.dart';

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
              _createDrawerItem(
                context: context,
                icon: Icons.map,
                text: 'E X P L O R A R',
                onTap: () => _navigateToPage(context, const ExplorePage()),
              ),
              _createDrawerItem(
                context: context,
                icon: Icons.favorite,
                text: 'F A V O R I T O S',
                onTap: () => _navigateToPage(context, const FavoritesPage()),
              ),
              _createDrawerItem(
                context: context,
                icon: Icons.account_circle,
                text: 'P E R F I L',
                onTap: () => _navigateToPage(context, ProfilePage()),
              ),
              _createDrawerItem(
                context: context,
                icon: Icons.settings,
                text: 'C O N F I G U R A Ç Õ E S',
                onTap: () => _navigateToPage(context, const SettingsPage()),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 25.0, bottom: 25),
            child: ListTile(
              title: const Text("L O G O U T"),
              leading: const Icon(Icons.logout),
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _createDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 25.0, top: 10),
      child: ListTile(
        title: Text(text),
        leading: Icon(icon),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
      ),
    );
  }

  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => page,
      ),
    );
  }

  void _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await AuthService().signOut();
    } catch (e) {
      _displayMessage(context, "Erro ao fazer logout: $e");
    } finally {
      Navigator.pop(context);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginOrRegister(),
        ),
        (route) => false,
      );
    }
  }

  void _displayMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message),
      ),
    );
  }
}

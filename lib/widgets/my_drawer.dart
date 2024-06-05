import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:peakfinder/auth/auth_service.dart';
import 'package:peakfinder/screens/favorites_page.dart';
import 'package:peakfinder/screens/explore_page.dart';
import 'package:peakfinder/screens/profile_page.dart';
import 'package:peakfinder/screens/settings_page.dart';
import 'package:peakfinder/auth/login_or_register.dart';

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

              // favorites list tile
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

              // profile list tile
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

              // settings list tile
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
              onTap: () async {
                await _logout(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final Logger logger = Logger('MyDrawer');
    // Mostrar indicador de carregamento
    showDialog(
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: false,
    );

    try {
      await AuthService().signOut();
      logger.info("User signed out successfully");

      if (context.mounted) {
        // Fechar indicador de carregamento
        Navigator.of(context, rootNavigator: true).pop();

        // Navegar para a página LoginOrRegister e remover todas as páginas anteriores
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginOrRegister(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Fechar indicador de carregamento
        Navigator.of(context, rootNavigator: true).pop();
        
        // Exibir mensagem de erro se ocorrer
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Erro ao fazer logout"),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }
}

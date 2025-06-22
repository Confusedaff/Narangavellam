import 'package:app_ui/app_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
//import 'package:narangavellam/navigation/navigation.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.navigationShell,super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return HomeView(navigationShell: navigationShell,);
  }
}


class HomeView extends StatelessWidget {
  const HomeView({required this.navigationShell,super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: navigationShell,
     // bottomNavigationBar: BottomNavBar(navigationShell: navigationShell),
      );
  }
}


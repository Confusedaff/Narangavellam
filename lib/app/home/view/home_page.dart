import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:narangavellam/feed/post/video/widgets/video_player_inherited_widget.dart';
import 'package:narangavellam/navigation/navigation.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.navigationShell,super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return HomeView(navigationShell: navigationShell);
  }
}

class HomeView extends StatefulWidget {
  const HomeView({required this.navigationShell,super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late VideoPlayerState _videoPlayerState;
  
  @override
  void initState(){
    super.initState();
    _videoPlayerState = VideoPlayerState();
  }

  @override
  Widget build(BuildContext context) {
    return VideoPlayerInheritedWidget(
      videoPlayerState: _videoPlayerState,
      child: AppScaffold(
        body: widget.navigationShell,
        bottomNavigationBar: BottomNavBar(navigationShell: widget.navigationShell),
        ),
    );
  }
}

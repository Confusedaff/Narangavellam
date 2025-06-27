import 'dart:async';

import 'package:animations/animations.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:narangavellam/app/app.dart';
import 'package:narangavellam/app/home/home.dart';
import 'package:narangavellam/app/user_profile/view/user_profile_page.dart';
import 'package:narangavellam/auth/view/auth_page.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:user_repository/user_repository.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root'); 

GoRouter router(AppBloc appBloc) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey, 
    initialLocation: '/feed',
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
      ),



      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/route',builder: (context,state) => AppScaffold(body: Center(child: Text('Route Page',style: context.headlineSmall,)
        ,),),),
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey, 
        builder: (context, state, navigationShell) {
          return HomePage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/feed',
              pageBuilder: (context, state) {
                return CustomTransitionPage(
                  child: AppScaffold(
                    body: Center(
                      child: ElevatedButton(onPressed: () => context.push('/route'), child: const Text('Go to route')),
                    ),
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SharedAxisTransition(
                      animation: animation,
                      secondaryAnimation: secondaryAnimation,
                      transitionType: SharedAxisTransitionType.horizontal,
                      child: child,
                    );
                  },
                );
              },
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/timeline',
              pageBuilder: (context, state) {
                return CustomTransitionPage(
                  child: AppScaffold(
                    body: Center(
                      child: Text(
                        'TimeLine',
                        style: context.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
                      child: child,
                    );
                  },
                );
              },
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/create_media',
              redirect: (context, state) => null,
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/reels',
              pageBuilder: (context, state) {
                return CustomTransitionPage(
                  child: AppScaffold(
                    body: Center(
                      child: Text(
                        'Reels',
                        style: context.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
                      child: child,
                    );
                  },
                );
              },
            ),
          ]),

          StatefulShellBranch(routes: [
            GoRoute(
              path: '/user',
              pageBuilder: (context, state) {

                final user = context.select((AppBloc bloc) => bloc.state.user);

                return CustomTransitionPage(
                  child: UserProfilePage(
                    userId: user.id,
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SharedAxisTransition(
                      animation: animation,
                      secondaryAnimation: secondaryAnimation,
                      transitionType: SharedAxisTransitionType.horizontal,
                      child: child,
                    );
                  },
                );
              },
               routes: [
                    GoRoute(
                      path: 'create_post',
                      name: 'create_post',
                      parentNavigatorKey: _rootNavigatorKey,
                      pageBuilder: (context, state) {
                        //final pickVideo = state.extra as bool? ?? false;
                        return CustomTransitionPage(
                          key: state.pageKey,
                          child: const UserProfileCreatePost(),//pickVideo: pickVideo),
                          transitionsBuilder: (
                            context,
                            animation,
                            secondaryAnimation,
                            child,
                          ) {
                            return SharedAxisTransition(
                              animation: animation,
                              secondaryAnimation: secondaryAnimation,
                              transitionType:
                                  SharedAxisTransitionType.horizontal,
                              child: child,
                            );
                          },
                        );
                      },
                      routes: [
                        GoRoute(
                          name: 'publish_post',
                          path: 'publish_post',
                          parentNavigatorKey: _rootNavigatorKey,
                          pageBuilder: (context, state) {
                            final props = state.extra! as CreatePostProps;

                            return CustomTransitionPage(
                              key: state.pageKey,
                              child: CreatePostPage(props: props),
                              transitionsBuilder: (
                                context,
                                animation,
                                secondaryAnimation,
                                child,
                              ) {
                                return SharedAxisTransition(
                                  animation: animation,
                                  secondaryAnimation: secondaryAnimation,
                                  transitionType:
                                      SharedAxisTransitionType.horizontal,
                                  child: child,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'statistics',
                      name: 'user_statistics',
                      parentNavigatorKey: _rootNavigatorKey,
                      pageBuilder: (context, state) {
                        final userId = state.uri.queryParameters['user_id'] ?? context.read<AppBloc>().state.user.id;
                        final tabIndex = state.extra as int? ?? 0;

                        return CustomTransitionPage(
                          key: state.pageKey,
                          child: BlocProvider(
                            create: (context) => UserProfileBloc(
                              userId: userId,
                              userRepository: context.read<UserRepository>(),
                              postsRepository: context.read<PostsRepository>(),
                            )
                              ..add(const UserProfileSubscriptionRequested())
                              ..add(
                                const UserProfileFollowingsCountSubscriptionRequested(),
                              )
                              ..add(
                                const UserProfileFollowersCountSubscriptionRequested(),
                              ),
                            child: UserProfileStatistics(tabIndex: tabIndex),
                          ),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return SharedAxisTransition(
                              animation: animation,
                              secondaryAnimation: secondaryAnimation,
                              transitionType:
                                  SharedAxisTransitionType.horizontal,
                              child: child,
                            );
                          },
                        );
                      },
                    ),
                  ],
            ),
          ],
          ),
        ],
      ),
    ],

    
    redirect: (context, state) {
      final authenticated = appBloc.state.status == AppStatus.authenticated;
      final authenticating = state.matchedLocation == '/auth';
      final isInFeed = state.matchedLocation == '/feed';

      if (isInFeed && !authenticated) return '/auth';
      if (!authenticated) return '/auth';
      if (authenticating && authenticated) return '/feed';

      return null;
    },
    refreshListenable: GoRouterAppBlocRefreshStream(appBloc.stream),
  );
}

/// ChangeNotifier to refresh GoRouter when AppBloc emits a new state
class GoRouterAppBlocRefreshStream extends ChangeNotifier {
  GoRouterAppBlocRefreshStream(Stream<AppState> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

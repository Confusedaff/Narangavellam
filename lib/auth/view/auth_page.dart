import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:narangavellam/auth/cubit/auth_cubit.dart';
import 'package:narangavellam/auth/login/view/login_page.dart';
import 'package:narangavellam/auth/sign_up/view/sign_up_page.dart';


/// {@template auth_page}
/// Auth page. Shows login or signup page depending on the state of `AuthCubit`.
/// {@endtemplate}
class AuthPage extends StatelessWidget {
  /// {@macro auth_page}
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit(),
      child: const AuthView(),
    );
  }
}

/// {@template auth_view}
/// Auth view. Shows login or signup page depending on the state of [AuthCubit].
/// {@endtemplate}
class AuthView extends StatelessWidget {
  /// {@macro auth_view}
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    final showLogin = context.select((AuthCubit b) => b.state);

    return PageTransitionSwitcher(
      reverse: showLogin,
      transitionBuilder: (
        child,
        animation,
        secondaryAnimation,
      ) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
        );
      },
      child: showLogin ? const LoginPage() : const  SignUpPage()
    );
  }
}

import 'package:app_ui/app_ui.dart';
import 'package:blocks_ui/blocks_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:narangavellam/auth/sign_up/signup.dart';
import 'package:narangavellam/auth/sign_up/widgets/sign_up_button.dart';
import 'package:user_repository/user_repository.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SignUpCubit(
        userRepository: context.read<UserRepository>(),
      ),
      child: const SignUpView(),
    );
  }
}

class SignUpView extends StatelessWidget {
  const SignUpView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      releaseFocus: true,
      resizeToAvoidBottomInset: true,
      body: AppConstrainedScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xlg),
        child: Column(
          children: [
            SizedBox(height: AppSpacing.xxxlg + AppSpacing.xlg),
            AppLogo(
              fit: BoxFit.fitHeight,
            ),
            
            Expanded(
                child: Column(
              children: [
                Align(child: AvatarImagePicker()),
                SizedBox(height: AppSpacing.md,),
                SignUpForm(),
                SizedBox(height: AppSpacing.xlg,),
                SignUpButton(),
              ],
            ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.lg),
              child: SignInIntoAccountButton(),
            ),
          ],
        ),
      ),
    );
  }
}

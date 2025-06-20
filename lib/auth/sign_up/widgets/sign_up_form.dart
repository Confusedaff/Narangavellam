import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:narangavellam/auth/sign_up/signup.dart';
import 'package:narangavellam/auth/sign_up/widgets/password_form_field.dart';
import 'package:narangavellam/auth/sign_up/widgets/username_from_field.dart';

class SignUpForm extends StatelessWidget {
  const SignUpForm({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EmailFormField(),
        SizedBox(height: AppSpacing.md,),
        FullNameTextField(),
        SizedBox(height: AppSpacing.md,),
        UsernameTextField(),
        SizedBox(height: AppSpacing.md,),
        PasswordTextField(),
        SizedBox(height: AppSpacing.md,),
      ],
    );
  }
}

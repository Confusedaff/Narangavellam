import 'package:flutter/material.dart';
import 'package:narangavellam/auth/login/widgets/email_form_field.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment:CrossAxisAlignment.start,
      children: [
        EmailFormField(),
      ],
    );
  }
}

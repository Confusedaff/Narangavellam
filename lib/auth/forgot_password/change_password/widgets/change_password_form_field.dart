import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:narangavellam/app/view/app.dart';
import 'package:narangavellam/auth/forgot_password/change_password/cubit/change_password_cubit.dart';
import 'package:narangavellam/auth/forgot_password/change_password/widgets/change_password_field.dart';
import 'package:narangavellam/auth/forgot_password/change_password/widgets/change_password_otp_form_field.dart';
import 'package:shared/shared.dart';

class ChangePasswordForm extends StatefulWidget {
  const ChangePasswordForm({super.key});

  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  @override
  void initState() {
    super.initState();
    context.read<ChangePasswordCubit>().resetState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<ChangePasswordCubit>().resetState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChangePasswordCubit, ChangePasswordState>(
      listener: (context, state) {
        if (state.status.isError) {
         openSnackbar(
           SnackbarMessage.error(
             title: changePasswordStatusMessage[state.status]!.title,
             description:
                 changePasswordStatusMessage[state.status]?.description,
           ),
           clearIfQueue: true,
         );
        }
      },
      listenWhen: (p, c) => p.status != c.status,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const ChangePasswordOtpField(),
          const ChangePasswordField(),
        ].spacerBetween(height: AppSpacing.md),
      ),
    );
  }
}

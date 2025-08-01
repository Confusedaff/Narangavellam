import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:narangavellam/auth/cubit/manage_password_cubit.dart';
import 'package:narangavellam/auth/forgot_password/cubit/forgot_password_cubit.dart';
import 'package:narangavellam/l10n/l10n.dart';
import 'package:shared/shared.dart';

class ForgotButtonSendEmailButton extends StatelessWidget {
  const ForgotButtonSendEmailButton({super.key});

  void _onPressed(BuildContext context) =>
      context.read<ForgotPasswordCubit>().onSubmit(
            onSuccess: () => context
                .read<ManagePasswordCubit>()
                .changeScreen(showForgotPassword: false),
          );

  @override
  Widget build(BuildContext context) {
    final isLoading = context
        .select((ForgotPasswordCubit bloc) => bloc.state.status.isLoading);
    final child = Tappable.faded(
      throttle: true,
      throttleDuration: 650.ms,
      backgroundColor: AppColors.blue,
      borderRadius: BorderRadius.circular(4),
      onTap: isLoading ? null : () => _onPressed(context),
      child: isLoading
          ? Center(child: AppCircularProgress(context.adaptiveColor))
          : Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm + AppSpacing.xxs,
              ),
              child: Align(
                child: Text(
                  context.l10n.furtherText,
                  style: context.labelLarge?.copyWith(
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: switch (context.screenWidth) {
          > 600 => context.screenWidth * .6,
          _ => context.screenWidth,
        },
      ),
      child: child,
    );
  }
}

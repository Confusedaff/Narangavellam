
import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:narangavellam/auth/view/auth_page.dart';
import 'package:narangavellam/l10n/arb/app_localizations.dart';

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme:const AppTheme().theme,
      darkTheme: const AppDarkTheme().theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home:const AuthPage(),
    );
  }
}

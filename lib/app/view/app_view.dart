
import 'package:api_repository/api_repository.dart';
import 'package:env/env.dart';
import 'package:flutter/material.dart';
import 'package:narangavellam/app/di/di.dart';
import 'package:narangavellam/l10n/arb/app_localizations.dart';
import 'package:shared/shared.dart';

class App extends StatelessWidget {
  const App({super.key, required ApiRepository apiRepository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home:SafeArea(
        child: Scaffold(
          body: Text(
            getIt<AppFlavor>().getEnv(Env.androidClientId),),
        ),
      ),
    );
  }
}

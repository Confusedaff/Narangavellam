import 'package:api_repository/api_repository.dart';
import 'package:narangavellam/app/app.dart';
import 'package:narangavellam/bootstrap.dart';
import 'package:narangavellam/firebase_options_prod.dart';
import 'package:shared/shared.dart';

void main() {
  const apiRepository = ApiRepository();
  bootstrap(
    (powersyncRepository) {
      return const App(apiRepository: apiRepository);
    },
    options: DefaultFirebaseOptions.currentPlatform,
    appFlavor: AppFlavor.production(),
  );
}

import 'package:database_client/database_client.dart';
import 'package:env/env.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:narangavellam/app/app.dart';
import 'package:narangavellam/bootstrap.dart';
import 'package:narangavellam/firebase_options_prod.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:shared/shared.dart';
import 'package:supabase_authentication_client/supabase_authentication_client.dart';
import 'package:token_storage/token_storage.dart';
import 'package:user_repository/user_repository.dart';

void main() {
  bootstrap(
    (powersyncRepository) async{

      final androidClientId = getIt<AppFlavor>().getEnv(Env.androidClientId);
      final webClientId = getIt<AppFlavor>().getEnv(Env.webClientId);

      final tokenStorage = InMemoryTokenStorage();
      final googleSignIn = GoogleSignIn(
        clientId:androidClientId,
        serverClientId: webClientId,
      );
      final supabaseAuthenticationClient = SupabaseAuthenticationClient(
        powerSyncRepository: powersyncRepository,
        tokenStorage: tokenStorage,
        googleSignIn: googleSignIn,
        );
    final powerSyncDatabaseClient = PowerSyncDatabaseClient( powerSyncRepository: powersyncRepository);
      final userRepository = UserRepository(
        databaseClient: powerSyncDatabaseClient,
        authenticationClient: supabaseAuthenticationClient,);
      final postsRepository = PostsRepository(databaseClient: powerSyncDatabaseClient);
      
      return App(
        user: await userRepository.user.first, 
        userRepository: userRepository,
        postsRepository: postsRepository,
        );
    },
    options: DefaultFirebaseOptions.currentPlatform,
    appFlavor: AppFlavor.production(),
  );
}

  

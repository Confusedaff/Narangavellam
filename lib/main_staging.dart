import 'package:chats_repository/chats_repository.dart';
import 'package:database_client/database_client.dart';
import 'package:env/env.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:narangavellam/app/app.dart';
import 'package:narangavellam/bootstrap.dart';
import 'package:narangavellam/firebase_options_stg.dart';
import 'package:persistent_storage/persistent_storage.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:search_repository/search_repository.dart';
import 'package:shared/shared.dart';
import 'package:stories_repository/stories_repository.dart';
import 'package:supabase_authentication_client/supabase_authentication_client.dart';
import 'package:token_storage/token_storage.dart';
import 'package:user_repository/user_repository.dart';

void main() {
  bootstrap(
    (powersyncRepository,
    sharedPreferences,
    firebaseRemoteConfigRepository,) async{

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

      final persistentStorage =
        PersistentStorage(sharedPreferences: sharedPreferences);

      final storiesStorage = StoriesStorage(storage: persistentStorage);

     final powerSyncDatabaseClient = PowerSyncDatabaseClient( powerSyncRepository: powersyncRepository);
      final userRepository = UserRepository(
        databaseClient: powerSyncDatabaseClient,
        authenticationClient: supabaseAuthenticationClient,);
       final postsRepository = PostsRepository(databaseClient: powerSyncDatabaseClient);
        final searchRepository = SearchRepository(databaseClient: powerSyncDatabaseClient);
         final storiesRepository = StoriesRepository(databaseClient: powerSyncDatabaseClient,storage: storiesStorage);
         final chatsRepository = ChatsRepository(databaseClient: powerSyncDatabaseClient);
        
      return App(
        user: await userRepository.user.first, 
        userRepository: userRepository,
        postsRepository: postsRepository,
        firebaseRemoteConfigRepository: firebaseRemoteConfigRepository,
        searchRepository: searchRepository,
        storiesRepository: storiesRepository,
        chatsRepository: chatsRepository,
        );
    },
    options: DefaultFirebaseOptions.currentPlatform,
    appFlavor: AppFlavor.staging(),
  );
}

  

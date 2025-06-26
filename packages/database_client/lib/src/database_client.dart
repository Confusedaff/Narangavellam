// ignore_for_file: public_member_api_docs

import 'package:powersync_repository/powersync_repository.dart';
import 'package:shared/shared.dart';
import 'package:user_repository/user_repository.dart';

abstract class UserBaseRepository{
  const UserBaseRepository();
  String? get currentUserId;
  Stream <User> profile({required String userId });
  Stream <int> followingsCountOf({required String userId });
  Stream <int> followersCountOf({required String userId });
  Stream<bool> followingStatus({
    required String userId,
    String? followerId,
  });
  Future<bool> isFollowed({
  required String followerId,
  required String userId,
  });

  Future<void> follow({
    required String followToId,
    String? followerId,
  });

  Future<void> unfollow({required String unfollowId, String? unfollowerId});

}

abstract class PostsBaseRepository {

  const PostsBaseRepository();

  Stream<int> postsAmountof({required String userId});

  Future<Post?>createPost({
    required String id,
    required String caption,
    required String media,
  });
}

abstract class DatabaseClient implements UserBaseRepository, PostsBaseRepository{
  const DatabaseClient();
}

class PowerSyncDatabaseClient extends DatabaseClient{
  const PowerSyncDatabaseClient({
    required PowerSyncRepository powerSyncRepository,
  }) : _powerSyncRepository = powerSyncRepository;

  final PowerSyncRepository _powerSyncRepository;

  @override
  String? get currentUserId => _powerSyncRepository.supabase.auth.currentSession?.user.id;

  @override
  Stream <User> profile({required String userId}) => _powerSyncRepository.db().watch(
    '''
    SELECT * FROM profiles WHERE id = ?
    ''',
    parameters: [userId],
    )
  .map((event) => event.isEmpty ? User.anonymous: User.fromJson(event.first),
  );
  
  @override
  Stream<int> postsAmountof({required String userId}) =>
    _powerSyncRepository.db().watch(
    '''
    SELECT COUNT(*) as posts_count FROM posts where user_id = ?
    ''',
    parameters: [userId],
    )
  .map((event) => event.map((element) => element['posts_count']).first as int,
  );
  
  @override
  Stream<int> followersCountOf({required String userId}) =>
    _powerSyncRepository.db().watch(
    'SELECT COUNT(*) AS subscription_count FROM subscriptions '
    'WHERE subscribed_to_id = ?',
    parameters: [userId],
  ).map(
    (event) => event.first['subscription_count'] as int,
  );
  
  @override
  Stream<int> followingsCountOf({required String userId}) =>
  _powerSyncRepository.db().watch(
    'SELECT COUNT(*) AS subscription_count FROM subscriptions '
    'WHERE subscriber_id = ?',
    parameters: [userId],
  ).map(
    (event) => event.first['subscription_count'] as int,
  );
  
  @override
  Future<void> follow({required String followToId, String? followerId}) async {
    if (currentUserId == null) return;
    if (followToId == currentUserId) return;
    final exists = await isFollowed(
      followerId: followerId ?? currentUserId!,
      userId: followToId,
    );
    if (!exists) {
      await _powerSyncRepository.db().execute(
        '''
          INSERT INTO subscriptions(id, subscriber_id, subscribed_to_id)
            VALUES(uuid(), ?, ?)
      ''',
        [followerId ?? currentUserId!, followToId],
      );
      return;
  }
  await unfollow(
      unfollowId: followToId,
      unfollowerId: followerId ?? currentUserId!,
    );
}
  
  @override
  Future<bool> isFollowed({required String followerId, required String userId}) async{
    final result = await _powerSyncRepository.db().execute(
     '''
     SELECT 1 FROM subscriptions WHERE subscriber_id = ? AND subscribed_to_id = ?
      ''',
      [followerId, userId],
    );
    return result.isNotEmpty;
  }
  
  @override
  Future<void> unfollow({required String unfollowId, String? unfollowerId}) async {
    if (currentUserId == null) return;
    await _powerSyncRepository.db().execute(
      '''
          DELETE FROM subscriptions WHERE subscriber_id = ? AND subscribed_to_id = ?
      ''',
      [unfollowerId ?? currentUserId, unfollowId],
    );
  }
  
  @override
  Stream<bool> followingStatus({required String userId, String? followerId}) {
     if (followerId == null && currentUserId == null) {
      return const Stream.empty();
    }
    return _powerSyncRepository.db().watch(
      '''
    SELECT 1 FROM subscriptions WHERE subscriber_id = ? AND subscribed_to_id = ?
    ''',
      parameters: [followerId ?? currentUserId, userId],
    ).map((event) => event.isNotEmpty);
  }
  
  @override
  Future<Post?> createPost({
    required String id, 
    required String caption, 
    required String media,}) 
    async {
    if (currentUserId == null) return null;
    final result = await Future.wait([
      _powerSyncRepository.db().execute(
        '''
        INSERT INTO posts(id, user_id, caption, media, created_at)
        VALUES(?, ?, ?, ?, ?)
        RETURNING *
        ''',
        [
          id,
          currentUserId,
          caption,
          media,
          DateTime.timestamp().toIso8601String(),
        ],
      ),
      _powerSyncRepository.db().get(
        '''
      SELECT * FROM profiles WHERE id = ?
        ''',
        [currentUserId],
      ),
    ]);
    if (result.isEmpty) return null;
    final row = Map<String, dynamic>.from((result.first as ResultSet).first);
    final author = User.fromJson(result.last as Row);
    return Post.fromJson(row).copyWith(author: author);
  }
}
  

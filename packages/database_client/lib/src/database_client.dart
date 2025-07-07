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

  Future<void> updateUser({
    String? fullName,
    String? email,
    String? username,
    String? avatarUrl,
    String? pushToken,
  });

  Future<void> removeFollower({required String id});

   /// Returns a list of followings of the user identified by [userId].
  Future<List<User>> getFollowings({String? userId});

   /// Returns a list of followers of the user identified by [userId].
  Future<List<User>> getFollowers({String? userId});

  /// Broadcasts a list of followers of the user identified by [userId].
  Stream<List<User>> followers({required String userId});

  Future<void> follow({
    required String followToId,
    String? followerId,
  });

  Future<void> unfollow({required String unfollowId, String? unfollowerId});

  /// Looks up into a database a returns users associated with the provided
  /// [query].
  Future<List<User>> searchUsers({
    required int limit,
    required int offset,
    required String? query,
    String? userId,
    String? excludeUserIds,
  });

}

abstract class PostsBaseRepository {

  const PostsBaseRepository();

  Stream<List<Post>> postsOf({String? userId});
  Stream<int> postsAmountof({required String userId});

  Future<Post?>createPost({
    required String id,
    required String caption,
    required String media,
  });

  /// Fetches the profiles of users who liked the post, identified by [postId]
  /// and who are in followings of the user identified by current user `id`.
  Future<List<User>> getPostLikersInFollowings({
    required String postId,
    int limit = 3,
    int offset = 0,
  });

  /// Returns the page of posts with provided [offset] and [limit].
  Future<List<Post>> getPage({
    required int offset,
    required int limit,
    bool onlyReels = false,
  });

  /// Returns a real-time stream of likes count of post by provided [id].
  Stream<int> likesOf({
    required String id,
    bool post = true,
  });

   /// Returns a real-time stream of whether the post by [id] is liked by user
  /// identified by [userId].
  Stream<bool> isLiked({
    required String id,
    String? userId,
    bool post = true,
  });

  /// Returns a stream of amount of comments of the post identified by [postId].
  Stream<int> commentsAmountOf({required String postId});

  /// Likes the post by provided either post or comment [id].
  Future<void> like({
    required String id,
    bool post = true,
  });

    /// Deletes the post with provided [id].
  /// Returns the optional `id` of the deleted post.
  Future<String?> deletePost({required String id});

  /// Updates the post with provided [id] and optional parameters to update.
  Future<Post?> updatePost({required String id, String? caption});

   /// Returns a stream of comments of the post identified by [postId].
  Stream<List<Comment>> commentsOf({required String postId});

  /// Created a comment with provided details.
  Future<void> createComment({
    required String content,
    required String postId,
    required String userId,
    String? repliedToCommentId,
  });

  /// Delete the comment by associated [id].
  Future<void> deleteComment({required String id});

  /// Returns a stream of replied comments of the comment identified by
  /// [commentId].
  Stream<List<Comment>> repliedCommentsOf({required String commentId});
}

abstract class DatabaseClient implements UserBaseRepository, PostsBaseRepository
{
  const DatabaseClient();
}

class PowerSyncDatabaseClient extends DatabaseClient{
  const PowerSyncDatabaseClient({
    required PowerSyncRepository powerSyncRepository,
  }) : _powerSyncRepository = powerSyncRepository;

  final PowerSyncRepository _powerSyncRepository;

  @override
  String? get currentUserId =>
     _powerSyncRepository.supabase.auth.currentSession?.user.id;

  @override
  Stream <User> profile({required String userId}) =>
     _powerSyncRepository.db().watch(
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
  Future<bool> isFollowed
  ({required String followerId, required String userId}) async{
    final result = await _powerSyncRepository.db().execute(
     '''
     SELECT 1 FROM subscriptions WHERE subscriber_id = ? AND subscribed_to_id = ?
      ''',
      [followerId, userId],
    );
    return result.isNotEmpty;
  }
  
  @override
  Future<void> unfollow({required String unfollowId, String? unfollowerId})
   async {
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
  Future<List<User>> getFollowers({String? userId}) async {
    final followersId = await _powerSyncRepository.db().getAll(
      'SELECT subscriber_id FROM subscriptions WHERE subscribed_to_id = ? ',
      [userId ?? currentUserId],
    );
    if (followersId.isEmpty) return [];

    final followers = <User>[];
    for (final followerId in followersId) {
      final result = await _powerSyncRepository.db().execute(
        'SELECT * FROM profiles WHERE id = ?',
        [followerId['subscriber_id']],
      );
      if (result.isEmpty) continue;
      final follower = User.fromJson(result.first);
      followers.add(follower);
    }
    return followers;
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

 @override
  Stream<List<User>> followers({required String userId}) async* {
    final streamResult = _powerSyncRepository.db().watch(
      'SELECT subscriber_id FROM subscriptions WHERE subscribed_to_id = ? ',
      parameters: [userId],
    );
    await for (final result in streamResult) {
      final followers = <User>[];
      final followersFutures = await Future.wait(
        result.where((row) => row.isNotEmpty).safeMap(
              (row) => _powerSyncRepository.db().getOptional(
                'SELECT * FROM profiles WHERE id = ?',
                [row['subscriber_id']],
              ),
            ),
      );
      for (final user in followersFutures) {
        if (user == null) continue;
        final follower = User.fromJson(user);
        followers.add(follower);
      }
      yield followers;
    }
  }

    @override
    Future<List<Post>> getPage({
      required int offset,
      required int limit,
      bool onlyReels = false,
    }) async {
      final result = await _powerSyncRepository.db().execute(
        '''
        SELECT
          posts.*,
          p.id as user_id,
          p.avatar_url as avatar_url,
          p.username as username,
          p.full_name as full_name
        FROM
          posts
        inner join profiles p on posts.user_id = p.id
        ORDER BY created_at DESC LIMIT ?1 OFFSET ?2
        ''',
        [limit, offset],
      );
      final posts = <Post>[];

        for (final row in result) {
          final json = Map<String, dynamic>.from(row);
          final post = Post.fromJson(json);
          posts.add(post);
        }
        return posts;
  }
  
  @override
  Future<List<User>> getFollowings({String? userId}) async {
    final followingsUserId = await _powerSyncRepository.db().getAll(
      'SELECT subscribed_to_id FROM subscriptions WHERE subscriber_id = ? ',
      [userId ?? currentUserId],
    );
    if (followingsUserId.isEmpty) return [];

    final followings = <User>[];
    for (final followingsUserId in followingsUserId) {
      final result = await _powerSyncRepository.db().execute(
        'SELECT * FROM profiles WHERE id = ?',
        [followingsUserId['subscribed_to_id']],
      );
      if (result.isEmpty) continue;
      final following = User.fromJson(result.first);
      followings.add(following);
    }
    return followings;
  }
  
   @override
  Future<void> removeFollower({required String id}) async {
    if (currentUserId == null) return;
    await _powerSyncRepository.db().execute(
      '''
          DELETE FROM subscriptions WHERE subscriber_id = ? AND subscribed_to_id = ?
      ''',
      [id, currentUserId],
    );
  }
  
   @override
  Future<void> updateUser({
    String? fullName,
    String? email,
    String? username,
    String? avatarUrl,
    String? pushToken,
    String? password,
  }) =>
      _powerSyncRepository.updateUser(
        email: email,
        password: password,
        data: {
          if (fullName != null) 'full_name': fullName,
          if (username != null) 'username': username,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
          if (pushToken != null) 'push_token': pushToken,
        },
      );

  @override
  Future<List<User>> getPostLikersInFollowings({
    required String postId,
    int limit = 3,
    int offset = 0,
  }) async {
    final result = await _powerSyncRepository.db().getAll(
      '''
      SELECT id, avatar_url, username, full_name
      FROM profiles
      WHERE id IN (
          SELECT l.user_id
          FROM likes l
          WHERE l.post_id = ?1
          AND EXISTS (
              SELECT *
              FROM subscriptions f
              WHERE f.subscribed_to_id = l.user_Id
              AND f.subscriber_id = ?2
          ) AND id <> ?2
      )
      LIMIT ?3 OFFSET ?4
      ''',
      [postId, currentUserId, limit, offset],
    );
    if (result.isEmpty) return [];
    return result.safeMap(User.fromJson).toList(growable: false);
  }

  @override
  Stream<int> likesOf({required String id, bool post = true}) {
    final statement = post ? 'post_id' : 'comment_id';
    return _powerSyncRepository.db().watch(
      '''
      SELECT COUNT(*) AS total_likes
      FROM likes
      WHERE $statement = ? AND $statement IS NOT NULL
      ''',
      parameters: [id],
    ).map((result) => result.safeMap((row) => row['total_likes']).first as int);
  }

    @override
  Stream<bool> isLiked({
    required String id,
    String? userId,
    bool post = true,
  }) {
    final statement = post ? 'post_id' : 'comment_id';
    return _powerSyncRepository.db().watch(
      '''
      SELECT EXISTS (
        SELECT 1 
        FROM likes
        WHERE user_id = ? AND $statement = ? AND $statement IS NOT NULL
      )
      ''',
      parameters: [userId ?? currentUserId, id],
    ).map((event) => (event.first.values.first! as int).isTrue);
  }

   @override
  Stream<int> commentsAmountOf({required String postId}) =>
      _powerSyncRepository.db().watch(
        '''
        SELECT COUNT(*) AS comments_count FROM comments
        WHERE post_id = ? 
        ''',
        parameters: [postId],
      ).map(
        (result) => result.map((row) => row['comments_count']).first as int,
      );

  @override
  Future<void> like({
    required String id,
    bool post = true,
  }) async {
    if (currentUserId == null) return;
    final statement = post ? 'post_id' : 'comment_id';
    final exists = await _powerSyncRepository.db().execute(
      'SELECT 1 FROM likes '
      'WHERE user_id = ? AND $statement = ? AND $statement IS NOT NULL',
      [currentUserId, id],
    );
    if (exists.isEmpty) {
      await _powerSyncRepository.db().execute(
        '''
          INSERT INTO likes(user_id, $statement, id)
            VALUES(?, ?, uuid())
      ''',
        [currentUserId, id],
      );
      return;
    }
    await _powerSyncRepository.db().execute(
      '''
          DELETE FROM likes 
          WHERE user_id = ? AND $statement = ? AND $statement IS NOT NULL
      ''',
      [currentUserId, id],
    );
  }

  @override
  Future<String?> deletePost({required String id}) async {
    final result = await _powerSyncRepository
        .db()
        .execute('DELETE FROM posts WHERE id = ? RETURNING id', [id]);
    if (result.isEmpty) return null;
    return result.first['id'] as String;
  }

    @override
  Future<Post?> updatePost({required String id, String? caption}) async {
    final row = await _powerSyncRepository.db().execute(
      '''
      UPDATE posts
      SET
        caption = ?2,
        updated_at = ?3
      WHERE id = ?1
      RETURNING *
      ''',
      [id, caption, DateTime.timestamp().toIso8601String()],
    );
    if (row.isEmpty) return null;
    final json = Map<String, dynamic>.from(row.first);
    return Post.fromJson(json);
  }
  
   @override
  Stream<List<Post>> postsOf({String? userId}) {
    if (currentUserId == null && userId == null) return const Stream.empty();
    if (userId == null) {
      return _powerSyncRepository.db().watch(
        '''
SELECT
  posts.*,
  p.id as user_id,
  p.avatar_url as avatar_url,
  p.username as username,
  p.full_name as full_name
FROM
  posts
  left join profiles p on posts.user_id = p.id 
WHERE user_id = ?1
ORDER BY created_at DESC
      ''',
        parameters: [currentUserId],
      ).map(
        (event) => event
            .safeMap((row) => Post.fromJson(Map<String, dynamic>.from(row)))
            .toList(growable: false),
      );
    }
    return _powerSyncRepository.db().watch(
      '''
SELECT
  posts.*,
  p.avatar_url as avatar_url,
  p.username as username,
  p.full_name as full_name
FROM
  posts
  left join profiles p on posts.user_id = p.id 
WHERE user_id = ?
ORDER BY created_at DESC
      ''',
      parameters: [userId],
    ).map(
      (event) => event
          .safeMap((row) => Post.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false),
    );
  }

   @override
  Future<List<User>> searchUsers({
    required int limit,
    required int offset,
    required String? query,
    String? userId,
    String? excludeUserIds,
  }) async {
    if (query == null || query.trim().isEmpty) return <User>[];
    query = query.removeSpecialCharacters();
    final excludeUserIdsStatement =
        excludeUserIds == null ? '' : 'AND id NOT IN ($excludeUserIds)';

    final result = await _powerSyncRepository.db().getAll(
      '''
SELECT id, avatar_url, full_name, username
  FROM profiles
WHERE (LOWER(username) LIKE LOWER('%$query%') OR LOWER(full_name) LIKE LOWER('%$query%'))
  AND id <> ?1 $excludeUserIdsStatement 
LIMIT ?2 OFFSET ?3
''',
      [currentUserId, limit, offset],
    );

    return result.safeMap(User.fromJson).toList(growable: false);
  }

  @override
  Stream<List<Comment>> commentsOf({required String postId}) =>
      _powerSyncRepository.db().watch(
        '''
SELECT 
  c1.*,
  p.avatar_url as avatar_url,
  p.username as username,
  p.full_name as full_name,
  COUNT(c2.id) AS replies
FROM 
  comments c1
  INNER JOIN
    profiles p ON p.id = c1.user_id
  LEFT JOIN
    comments c2 ON c1.id = c2.replied_to_comment_id
WHERE
  c1.post_id = ? AND c1.replied_to_comment_id IS NULL
GROUP BY
    c1.id, p.avatar_url, p.username, p.full_name
ORDER BY created_at ASC
''',
        parameters: [postId],
      ).map(
        (result) => result.safeMap(Comment.fromRow).toList(growable: false),
      );

  @override
  Future<void> createComment({
    required String postId,
    required String userId,
    required String content,
    String? repliedToCommentId,
  }) =>
      _powerSyncRepository.db().execute(
        '''
INSERT INTO
  comments(id, post_id, user_id, content, created_at, replied_to_comment_id)
VALUES(uuid(), ?, ?, ?, ?, ?)
''',
        [
          postId,
          userId,
          content,
          DateTime.timestamp().toIso8601String(),
          repliedToCommentId,
        ],
      );

  @override
  Future<void> deleteComment({required String id}) =>
      _powerSyncRepository.db().execute(
        '''
DELETE FROM comments
WHERE id = ?
''',
        [id],
      );

   @override
  Stream<List<Comment>> repliedCommentsOf({required String commentId}) =>
      _powerSyncRepository.db().watch(
        '''
SELECT 
  c1.*,
  p.avatar_url as avatar_url,
  p.username as username,
  p.full_name as full_name
FROM 
  comments c1
  INNER JOIN
    profiles p ON p.id = c1.user_id
WHERE
  c1.replied_to_comment_id = ? 
GROUP BY
    c1.id, p.avatar_url, p.username, p.full_name
ORDER BY created_at ASC
''',
        parameters: [commentId],
      ).map(
        (result) => result.safeMap(Comment.fromRow).toList(growable: false),
      );
}

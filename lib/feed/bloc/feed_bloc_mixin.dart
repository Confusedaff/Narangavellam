part of 'feed_bloc.dart';

typedef PaginatedFeedResult
    = Future<({int newPage, bool hasMore, List<InstaBlock> blocks})>;

typedef ListPostMapper = List<InstaBlock> Function(List<Post> post);

/// Represents the different types of page updates.
///
/// This enum defines three types of page updates: create, delete, and update.
/// It also provides convenient boolean getters to check the type of the update.
/// - `isCreate` returns true if the update is of type create.
/// - `isDelete` returns true if the update is of type delete.
/// - `isUpdate` returns true if the update is of type update.
enum PageUpdateType {
  create,
  delete,
  update;

  bool get isCreate => this == PageUpdateType.create;
  bool get isDelete => this == PageUpdateType.delete;
  bool get isUpdate => this == PageUpdateType.update;
}

/// {@template page_update}
/// Represents a page update.
///
/// This class encapsulates information about a page update, including the new
/// post and the type of update.
/// It provides getters to access the new large block and new reel block derived
/// from the new post.
/// The `onUpdate` method can be used to update a block with a new block.
/// The boolean getters `isCreate`, `isDelete`, and `isUpdate` can be used to
/// check the type of the update.
/// The `canUpdateReel` getter returns true if the new post's media is a reel.
///
/// Example usage:
/// ```dart
/// final update = PageUpdate(newPost: post, type: PageUpdateType.create);
/// final newLargeBlock = update.newLargeBlock;
/// final newReelBlock = update.newReelBlock;
/// final updatedBlock = update.onUpdate(oldBlock, newBlock);
/// final isCreate = update.isCreate;
/// final isDelete = update.isDelete;
/// final isUpdate = update.isUpdate;
/// final canUpdateReel = update.canUpdateReel;
/// ```
///
/// See also:
/// - `Post` class for representing a post
/// - `PageUpdateType` enum for representing the type of a page update
/// - `PostLargeBlock` class for representing a large block of a post
/// - `PostReelBlock` class for representing a reel block of a post
/// {@endtemplate}
sealed class PageUpdate {
  const PageUpdate({
    required this.newPost,
    required this.type,
  });

  final Post newPost;
  final PageUpdateType type;

  /// Returns the new large block derived from the `newPost` by calling the
  /// `toPostLargeBlock()` method.
  PostLargeBlock get newLargeBlock => newPost.toPostLargeBlock;
  PostReelBlock get newReelBlock => newPost.toPostReelBlock;

  /// Returns the new reel block derived from the `newPost` by calling the
  /// `toPostReelBlock()` method.
  //PostReelBlock get newReelBlock => newPost.toPostReelBlock;

  /// Updates a [PostBlock] with a new block.
  ///
  /// This method takes in a [block] of type [T] and a [newBlock] of type
  /// [PostBlock] and returns a new [PostBlock] that is updated based on the
  /// provided [newBlock].
  ///
  /// Example usage:
  /// ```dart
  /// final updatedBlock = onUpdate<PostLargeBlock>(block, newBlock);
  /// ```
  ///
  /// Note: The [block] and [newBlock] should have the same type [T].
  /// If the [block] and [newBlock] have different types, the method will throw
  /// an error.
  ///
  PostBlock onUpdate<T>(T block, PostBlock newBlock);

  bool get isCreate => type.isCreate;
  bool get isDelete => type.isDelete;
  bool get isUpdate => type.isUpdate;

  /// Returns a boolean value indicating whether the `newPost` media is a reel.
  bool get canUpdateReel => newPost.media.isReel;
}

/// {@template feed_page_update}
/// Represents a page update for the feed.
///
/// This class extends the [PageUpdate] class and provides an implementation
/// for the [onUpdate] method. It is specifically used for updating the feed
/// page.
///
/// The [onUpdate] method takes in a `block` of type `T` and a `newBlock` of
/// type [PostBlock] and returns a new [PostBlock] that is updated based on
/// the provided `newBlock`. If the `block` is of any other type, it throws an
/// [UnsupportedError] with a message indicating the unsupported block type.
/// {@endtemplate}
final class FeedPageUpdate extends PageUpdate {
  const FeedPageUpdate({required super.newPost, required super.type});

  @override
  PostBlock onUpdate<T>(T block, PostBlock newBlock) => switch (block) {
        final PostLargeBlock block => block.copyWith(caption: newBlock.caption),
        //final PostReelBlock block => block.copyWith(caption: newBlock.caption),
        _ => throw UnsupportedError('Unsupported block type: $block'),
      };
}

/// {@template feed_bloc_mixin}
/// A mixin class that provides common functionality for a feed bloc.
///
/// This mixin class is intended to be used with a `Bloc` class that handles
/// feed-related events and states.
/// It provides methods and properties for fetching feed pages, getting posts
/// by ID, updating blocks, and inserting sponsored blocks.
///
/// To use this mixin, implement the necessary dependencies:
/// - `PostsRepository` for fetching posts and post likers
/// - `FirebaseRemoteConfigRepository` for fetching remote data
///
/// Example usage:
/// ```dart
/// class MyFeedBloc extends Bloc<FeedEvent, FeedState> with FeedBlocMixin {
///   // Implement necessary dependencies
///   PostsRepository get postsRepository => ...
///   FirebaseRemoteConfigRepository get firebaseRemoteConfigRepository => ...
///
///   // Implement other methods and properties specific to your feed bloc
///   ...
/// }
/// ```
///
/// Note: This mixin assumes that the `Bloc` class has already implemented the
///  necessary event and state classes for feed-related functionality.
/// It also assumes that the `PostsRepository` and
/// `FirebaseRemoteConfigRepository` dependencies have been properly
/// initialized.
///
/// See also:
/// - `Bloc` class for handling feed-related events and states
/// - `PostsRepository` class for fetching posts and post likers
/// - `FirebaseRemoteConfigRepository` class for fetching remote data
/// {@endtemplate}

mixin FeedBlocMixin on Bloc<FeedEvent,FeedState>{

  int get feedPageLimit => 10;

  PostsRepository get postsRepository;
  FirebaseRemoteConfigRepository get firebaseRemoteConfigRepository;

  Future<PostBlock?> getPostBy(String id) async {
    final post = await postsRepository.getPostBy(id: id);
    return post?.toPostLargeBlock;
  }


  PaginatedFeedResult fetchFeedPage({
  int page = 0,
  ListPostMapper? mapper,
  bool withSponsoredBlocks = true,
  }) async {
  final currentPage = page;
  final posts = await postsRepository.getPage(
    offset: currentPage * feedPageLimit,
    limit: feedPageLimit,
  );

  final newPage = currentPage + 1;
  final hasMore = posts.length >= feedPageLimit;

  final instaBlocks =
      mapper?.call(posts) ?? postsToLargeBlocksMapper(posts);

  if(!withSponsoredBlocks){
    return (newPage: newPage, hasMore: hasMore, blocks: instaBlocks);
  }
  final blocks = await insertSponsoredBlocks(hasMore: hasMore, blocks: instaBlocks);
   return (newPage: newPage, hasMore: hasMore, blocks: blocks);
}

  List<InstaBlock> postsToLargeBlocksMapper(List<Post> posts) =>
    posts.map<InstaBlock>(
      (post) => post.topostlargeblock,).toList();

  
  List<InstaBlock> postsToReelBlockMapper(List<Post> posts) {
  final instaBlocks = <InstaBlock>[];
  for (final post in posts.where((post) => post.media.isReel)) {
    final reel = post.toPostReelBlock;
    instaBlocks.add(reel);
  }
  return instaBlocks;
  }

    Future<List<InstaBlock>> insertSponsoredBlocks({
    required bool hasMore,
    required List<InstaBlock> blocks,
  }) async {
    final sponsoredBlocksStringJson =
        firebaseRemoteConfigRepository.fetchRemoteData('sponsored_blocks');

    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(_computeSponsoredBlocks, [
      receivePort.sendPort,
      hasMore,
      blocks,
      sponsoredBlocksStringJson,
    ]);
    try {
  final insertedBlocks = await receivePort.first.timeout(3.seconds) as List<InstaBlock>;
  isolate.kill(priority: Isolate.immediate);
  return insertedBlocks;
} catch (e) {
  isolate.kill(priority: Isolate.immediate);
  logE('Isolate for sponsored blocks failed', error: e);
  return blocks; 
}
  }

     static Future<void> _computeSponsoredBlocks(List<dynamic> args) async {
    final sendPort = args[0] as SendPort;
    final hasMore = args[1] as bool;
    final blocks = args[2] as List<InstaBlock>;
    final sponsoredBlocksListJson =
        List<Map<String, dynamic>>.from(jsonDecode(args[3] as String) as List);

    final random = Random();

    var tempBlocks = [...blocks];
    var tempDataLength = tempBlocks.length;

    const skipRange = [1, 2, 3, 10];
    var previousSkipRangeIs1 = false;

    final sponsored =
        sponsoredBlocksListJson.take(20).map(InstaBlock.fromJson).toList();

    while (tempDataLength > 1) {
      final allowedSkipRange = switch ((previousSkipRangeIs1, tempDataLength)) {
        (true, > 10) => skipRange.sublist(1),
        (_, == 2) => [1],
        (_, == 3) => [1, 2],
        _ => skipRange,
      };

      final randomSponsoredPost = sponsored[random.nextInt(sponsored.length)];

      final randomSkipRange =
          allowedSkipRange[random.nextInt(allowedSkipRange.length)];

      previousSkipRangeIs1 = randomSkipRange == 1;

      tempBlocks = tempBlocks.sublist(randomSkipRange);
      blocks.insert(blocks.length - tempBlocks.length, randomSponsoredPost);
      tempDataLength = tempBlocks.length;
    }

    if (!hasMore) {
      return sendPort.send(
        blocks.followedBy([
          if (blocks.isNotEmpty) DividerHorizontalBlock(),
          const SectionHeaderBlock(
            sectionType: SectionHeaderBlockType.suggested,
          ),
        ]).toList(),
      );
    }

    return sendPort.send(blocks);
  }
}

extension on Feed {
  List<PostBlock> updateFeedPage({
    required PageUpdate update,
  }) {
    try {
      return feedPage.blocks.selectPostsBlock().updateBlocks(update: update);
    } catch (_) {
      rethrow;
    }
  }

  List<PostBlock> updateReelsPage({
    required PageUpdate update,
  }) {
    try {
      return reelsPage.blocks
          .selectPostsBlock()
          .updateBlocks(update: update, isReels: true);
    } catch (_) {
      rethrow;
    }
  }
}

extension on List<InstaBlock> {
  List<PostBlock> selectPostsBlock() => whereType<PostBlock>().toList();

  InstaBlock? findPostBlock({
    PostBlock? other,
    bool Function(PostBlock block)? test,
  }) =>
      firstWhereOrNull(
        (block) => switch (block) {
          final PostBlock block => (other == null || other.id == block.id) &&
              (test?.call(block) ?? true),
          _ => false,
        },
      );
}

extension on List<PostBlock> {
  List<PostBlock> updateBlocks({
    required PageUpdate update,
    bool isReels = false,
  }) =>
    switch ('') {
      _ when update is FeedPageUpdate => isReels
        ? _update<PostReelBlock>(
            update: update,
            isReels: isReels,
          )
        : _update<PostLargeBlock>(
            update: update,
            isReels: isReels,
          ),
      _ => this,
    };

  List<PostBlock> _update<T extends PostBlock>({
    required PageUpdate update,
    required bool isReels,
  }) {
    try {
      return updateWith<T>(
        newItem: isReels ? update.newReelBlock : update.newLargeBlock,
        onUpdate: update.onUpdate,
        isDelete: update.type.isDelete,
        findItemCallback: (block, newBlock) => block.id == newBlock.id,
      );
    } catch (_) {
      rethrow;
    }
  }
}

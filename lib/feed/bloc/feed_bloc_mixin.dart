part of 'feed_bloc.dart';

typedef PaginatedFeedResult
    = Future<({int newPage, bool hasMore, List<InstaBlock> blocks})>;

typedef ListPostMapper = List<InstaBlock> Function(List<Post> post);


mixin FeedBlocMixin on Bloc<FeedEvent,FeedState>{

  int get feedPageLimit => 10;

  PostsRepository get postsRepository;
  FirebaseRemoteConfigRepository get firebaseRemoteConfigRepository;

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

  //final postLikers = await _fetchPostLikersInFollowings(posts);

  final instaBlocks =
      mapper?.call(posts) ?? postsToLargeBlocksMapper(posts);//postLikers);
  if(!withSponsoredBlocks){
    return (newPage: newPage, hasMore: hasMore, blocks: instaBlocks);
  }
  final blocks = await insertSponsoredBlocks(hasMore: hasMore, blocks: instaBlocks);
   return (newPage: newPage, hasMore: hasMore, blocks: blocks);
}

  //   Future<List<List<User>>> _fetchPostLikersInFollowings(List<Post> posts) =>
  // Stream.fromIterable(posts)
  //   .asyncMap(
  //     (post) =>
  //       postsRepository.getPostLikersInFollowings(postId: post.id),
  //   )
  //   .toList();

  List<InstaBlock> postsToLargeBlocksMapper(
    List<Post> posts,
    //List<List<User>> postLikers,
  ) =>
  // posts.map<InstaBlock>((post) {
  //   final likersInFollowings = postLikers[posts.indexOf(post)];
  //   return post.toPostLargeBlock(likersInFollowings: likersInFollowings);
  // }).toList();

   posts.map<InstaBlock>((post) =>
    //final likersInFollowings = postLikers[posts.indexOf(post)];return
     post.topostlargeblock,//likersInFollowings: likersInFollowings);
  ).toList();

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
    isolate.kill(priority: Isolate.immediate);

    final insertedBlocks = await receivePort.first as List<InstaBlock>;
    return insertedBlocks;
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

    const skipRange = [1, 2, 3,];
    var previousSkipRangeIs1 = false;

    final sponsored =
        sponsoredBlocksListJson.take(20).map(InstaBlock.fromJson).toList();

    while (tempDataLength > 1) {
      final allowedSkipRange = switch ((previousSkipRangeIs1, tempDataLength)) {
        (true, > 3) => skipRange.sublist(1),
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

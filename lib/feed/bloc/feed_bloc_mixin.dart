part of 'feed_bloc.dart';

typedef PaginatedFeedResult
    = Future<({int newPage, bool hasMore, List<InstaBlock> blocks})>;

typedef ListPostMapper = List<InstaBlock> Function(List<Post> post);


mixin FeedBlocMixin on Bloc<FeedEvent,FeedState>{

  int get feedPageLimit => 10;

  PostsRepository get postsRepository;

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
  return (newPage: newPage, hasMore: hasMore, blocks: instaBlocks);
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
}

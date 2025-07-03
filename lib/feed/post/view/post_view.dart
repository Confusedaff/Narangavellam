import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:insta_blocks/insta_blocks.dart';
import 'package:instagram_blocks_ui/instagram_blocks_ui.dart';
import 'package:narangavellam/app/bloc/app_bloc.dart';
import 'package:narangavellam/app/user_profile/widgets/user_profile_props.dart';
import 'package:narangavellam/feed/bloc/feed_bloc.dart';
import 'package:narangavellam/feed/post/bloc/post_bloc.dart';
import 'package:narangavellam/feed/post/video/view/video_player.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:shared/shared.dart';
import 'package:user_repository/user_repository.dart';

class PostView extends StatelessWidget {
  const PostView({
    required this.block,
    this.builder,
    this.postIndex,
    this.withInViewNotifier = true,
    this.withCustomVideoPlayer = true,
    this.videoPlayerType = VideoPlayerType.feed,
    super.key,
  });

  final PostBlock block;
  final WidgetBuilder? builder;
  final int? postIndex;
  final bool withInViewNotifier;
  final bool withCustomVideoPlayer;
  final VideoPlayerType videoPlayerType;

  @override
  Widget build(BuildContext context) {
    final user = context.select((AppBloc bloc) => bloc.state.user);

    return BlocProvider(
      create: (context) => PostBloc(
        postId: block.id,
        userRepository: context.read<UserRepository>(),
        postsRepository: context.read<PostsRepository>(),
      )
        ..add(const PostLikesCountSubscriptionRequested())
        ..add(const PostCommentsCountSubscriptionRequested())
        ..add(const PostIsLikedSubscriptionRequested())
        ..add(
          PostAuthorFollowingStatusSubscriptionRequested(
            ownerId: block.author.id,
            currentUserId: user.id,
          ),
        )
        ..add(const PostLikersInFollowingsFetchRequested()),
      child: builder?.call(context) ??
          PostLargeView(
            block: block,
            postIndex: postIndex,
            withInViewNotifier: withInViewNotifier,
            withCustomVideoPlayer: withCustomVideoPlayer,
            videoPlayerType: videoPlayerType,
          ),
    );
  }
}

class PostLargeView extends StatelessWidget {
  const PostLargeView({
    required this.block,
    required this.postIndex,
    required this.withInViewNotifier,
    required this.withCustomVideoPlayer,
    required this.videoPlayerType,
    super.key,
  });

  final PostBlock block;
  final int? postIndex;
  final bool withInViewNotifier;
  final bool withCustomVideoPlayer;
  final VideoPlayerType videoPlayerType;

  // void _navigateToPostAuthor(
  //   BuildContext context, {
  //   required String id,
  //   UserProfileProps? props,
  // }) =>
  //     context.pushNamed(
  //       AppRoutes.userProfile.name,
  //       pathParameters: {'user_id': id},
  //       extra: props,
  //     );

  // void _handleOnPostTap(BuildContext context, {required BlockAction action}) =>
  //     action.when(
  //       navigateToPostAuthor: (action) =>
  //           _navigateToPostAuthor(context, id: action.authorId),
  //       navigateToSponsoredPostAuthor: (action) => _navigateToPostAuthor(
  //         context,
  //         id: action.authorId,
  //         props: UserProfileProps.build(
  //           isSponsored: true,
  //           promoBlockAction: action,
  //           sponsoredPost: block as PostSponsoredBlock,
  //         ),
  //       ),
  //     );

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PostBloc>();

    final isOwner = context.select((PostBloc bloc) => bloc.state.isOwner);
    final isLiked = context.select((PostBloc bloc) => bloc.state.isLiked);
    final likesCount = context.select((PostBloc bloc) => bloc.state.likes);
    final isFollowed = context.select((PostBloc bloc) => bloc.state.isFollowed);
    final commentsCount =
        context.select((PostBloc bloc) => bloc.state.commentsCount);
    final likersInFollowings =
        context.select((PostBloc bloc) => bloc.state.likersInFollowings);

    if (block is PostSponsoredBlock) {
    return PostSponsored(
    key: ValueKey(block.id),
    block: block as PostSponsoredBlock,
    isOwner: isOwner,
    isLiked: isLiked,
    likePost: () => bloc.add(const PostLikeRequested()),
    likesCount: likesCount,
    isFollowed: isOwner || (isFollowed ?? true),
    follow: () => bloc.add(PostAuthorFollowRequested(authorId: block.author.id)),
    enableFollowButton: true,
    onCommentsTap: (showFullSized) {
      // TODO(post): show comments modal sheet
    },
    postIndex: postIndex,
    withInViewNotifier: withInViewNotifier,
    commentsCount: commentsCount,
    postOptionsSettings: const PostOptionsSettings.viewer(),
  onUserTap: (userId) => context.pushNamed(
  'user_profile',
  pathParameters: {'user_id': userId},
  ),
  onPressed: (action) => action?.when(
    navigateToPostAuthor: (action) => context.pushNamed(
    'user_profile',
    pathParameters: {'user_id': action.authorId},
  ),
  navigateToSponsoredPostAuthor: (action) => context.pushNamed(
    'user_profile',
    pathParameters: {'user_id': action.authorId},
    extra: UserProfileProps.build(
      isSponsored: true,
      promoBlockAction: action,
      sponsoredPost: block as PostSponsoredBlock,
      ),
    ),
  ),
    onPostShareTap: (postId, author) {
      // TODO(post): show share post modal
      },
    );
  }
  return PostLarge(
      key: ValueKey(block.id),
      block: block,
      isOwner: isOwner,
      isLiked: isLiked,
      likePost: () => bloc.add(const PostLikeRequested()),
      likesCount: likesCount,
      isFollowed: isOwner || (isFollowed ?? true),
      follow: () =>
          bloc.add(PostAuthorFollowRequested(authorId: block.author.id)),
      enableFollowButton: true,
      commentsCount: commentsCount,
      postIndex: postIndex,
      likersInFollowings: likersInFollowings,
      withInViewNotifier: withInViewNotifier,
      // TODO(post): implement custom post avatar widget with stories
      postOptionsSettings: isOwner
          ? PostOptionsSettings.owner(
              onPostEdit: (block) => context.pushNamed(
                'post_edit',
                pathParameters: {'post_id': block.id},
                extra: block,
              ),
              onPostDelete: (_) {
              bloc.add(const PostDeleteRequested());
              context.read<FeedBloc>().add(
                FeedUpdateRequested(
                  update: FeedPageUpdate(
                    newPost: block.toPost, 
                    type:PageUpdateType.delete,
                    ),   
                  ),
                );
              },
            )
          : const PostOptionsSettings.viewer(),
          onCommentsTap: (showFullSized){

          },
          onUserTap: (userId) => context.pushNamed(
            'user_profile',
            pathParameters: {'user_id': userId},
          ),

          onPressed: (action) => action?.when(
            navigateToPostAuthor: (action) => context.pushNamed(
              'user_profile',
              pathParameters: {'user_id': action.authorId},
            ),
            navigateToSponsoredPostAuthor: (NavigateToSponsoredPostAuthorProfileAction action) {  },
          ),

          onPostShareTap: (postId, author) {
            // TODO(post): show share post modal
          },
        );

       

  }
}

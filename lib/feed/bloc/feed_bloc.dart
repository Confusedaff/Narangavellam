import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:insta_blocks/insta_blocks.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:shared/shared.dart';
import 'package:user_repository/user_repository.dart';

part 'feed_event.dart';
part 'feed_state.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  FeedBloc({
    required PostsRepository postsRepository,
  })  : _postsRepository = postsRepository,
        super(const FeedState.initial()) {
    on<FeedPageRequested>(_onFeedPageRequested);
  }

  final PostsRepository _postsRepository;

  static const _feedPageLimit = 10;

  Future<void> _onFeedPageRequested(
    FeedPageRequested event,
    Emitter<FeedState> emit,
    ) async {
    emit(state.loading());
    try {

      final currentPage = event.page ?? state.feed.feedPage.page;
      final posts = await _postsRepository.getPage(
        offset: currentPage * _feedPageLimit,
        limit: _feedPageLimit,
      );

      final postLikersFutures = posts.map(
        (post) => _postsRepository.getPostLikersInFollowings(postId: post.id),
      );

      final postLikers = await Future.wait(postLikersFutures);

      final newPage = currentPage + 1;

      final hasMore = posts.length >= _feedPageLimit;

      final blocks = List<InstaBlock>.generate(posts.length, (index) {
        final likersInFollowings = postLikers[index];
        final post = posts[index]
            .toPostLargeBlock(likersInFollowings: likersInFollowings);
        return post;
      });
        final feed = state.feed.copyWith(
        feedPage: state.feed.feedPage.copyWith(
          page: newPage,
          hasMore: hasMore,
          blocks: [...state.feed.feedPage.blocks, ...blocks],
          totalBlocks: state.feed.feedPage.totalBlocks + blocks.length,
        ),
      );
      emit(state.populated(feed: feed));
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.failure());
    }
  }
  
}

extension PostX on Post {
  /// Converts [Post] instance into [PostLargeBlock] instance.
  PostLargeBlock toPostLargeBlock({List<User> likersInFollowings = const []}) =>
      PostLargeBlock(
        id: id,
        author: PostAuthor.confirmed(
          id: author.id,
          avatarUrl: author.avatarUrl,
          username: author.displayUsername,
        ), // PostAuthor.confirmed
        createdAt: createdAt,
        media: media,
        caption: caption,
        //likersInFollowings: likersInFollowings,
        action: NavigateToPostAuthorProfileAction(authorId: author.id),
      ); // PostLargeBlock
}

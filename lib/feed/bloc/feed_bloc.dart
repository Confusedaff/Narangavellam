import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:insta_blocks/insta_blocks.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:shared/shared.dart';

part 'feed_bloc_mixin.dart';
part 'feed_event.dart';
part 'feed_state.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> with FeedBlocMixin{
  FeedBloc({
    required PostsRepository postsRepository,
  })  : _postsRepository = postsRepository,
        super(const FeedState.initial()) {
    on<FeedPageRequested>(_onFeedPageRequested);
    on<FeedRefreshRequested>(_onFeedRefreshRequested,transformer: throttleDroppable(duration:550.ms));
  }

  @override
  PostsRepository get postsRepository => _postsRepository;

  final PostsRepository _postsRepository;

  Future<void> _onFeedPageRequested(
    FeedPageRequested event,
    Emitter<FeedState> emit,
    ) async {
    emit(state.loading());
    try {

     final currentPage = event.page ?? state.feed.feedPage.page;
      final (:newPage, :hasMore, :blocks) =
    await fetchFeedPage(page: currentPage);

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

  Future<void> _onFeedRefreshRequested(
  FeedRefreshRequested event,
  Emitter<FeedState> emit,
  ) async {
  emit(state.loading());
  try {
    final (:newPage, :hasMore, :blocks) = await fetchFeedPage();
    final feed = state.feed.copyWith(
      feedPage: FeedPage(
        page: newPage,
        blocks: blocks,
        hasMore: hasMore,
        totalBlocks: blocks.length,
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
  PostLargeBlock get topostlargeblock =>//toPostLargeBlock({List<User> likersInFollowings = const []}) =>
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

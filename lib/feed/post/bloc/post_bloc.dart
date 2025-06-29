import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:insta_blocks/insta_blocks.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:user_repository/user_repository.dart';

part 'post_event.dart';
part 'post_state.dart';
part 'post_bloc.g.dart';

class PostBloc extends HydratedBloc<PostEvent, PostState> {
  PostBloc({
    required String postId,
    required UserRepository userRepository,
    required PostsRepository postsRepository,
  })  : 
        _postId = postId,
        _userRepository =userRepository,
        _postsRepository = postsRepository,
        super(const PostState.initial()) {
    on<PostLikesCountSubscriptionRequested>(
      _onPostLikesCountSubscriptionRequested,
    );
    on<PostIsLikedSubscriptionRequested> (_onPostIsLikedSubscriptionRequested);
    on<PostAuthorFollowingStatusSubscriptionRequested>(_onPostAuthorFollowingStatusSubscriptionRequested);
    on<PostCommentsCountSubscriptionRequested>(_onPostCommentsCountSubscriptionRequested);
  }

  final String _postId;
  final PostsRepository _postsRepository;
  final UserRepository _userRepository;

  Future<void> _onPostLikesCountSubscriptionRequested(
    PostLikesCountSubscriptionRequested event,
    Emitter<PostState> emit,
  ) async {
    await emit.forEach(
    _postsRepository.likesOf(id:_postId), onData: (likesCount) 
    => state.copyWith(likes: likesCount,),);
  }

  @override
  String get id => _postId;

  Future<void> _onPostIsLikedSubscriptionRequested(
  PostIsLikedSubscriptionRequested event,
  Emitter<PostState> emit,
  ) async {
    await emit.forEach(
      _postsRepository.isLiked(id: id),
      onData: (isLiked) => state.copyWith(isLiked: isLiked),
    );
  }

    Future<void> _onPostAuthorFollowingStatusSubscriptionRequested(
  PostAuthorFollowingStatusSubscriptionRequested event,
  Emitter<PostState> emit,
  ) async {
  if (event.currentUserId == event.ownerId) {
    return emit(state.copyWith(isOwner: true));
  }

  await emit.forEach(
    _userRepository.followingStatus(userId: event.ownerId),
    onData: (isFollowed) => state.copyWith(isFollowed: isFollowed),
  );
  }

  Future<void> _onPostCommentsCountSubscriptionRequested(
  PostCommentsCountSubscriptionRequested event,
  Emitter<PostState> emit,
  ) async {
    await emit.forEach(
      _postsRepository.commentsAmountOf(postId: id),
      onData: (commentsCount) => state.copyWith(commentsCount: commentsCount),
    );
  }
  
  @override
  PostState? fromJson(Map<String, dynamic> json) => PostState.fromJson(json);
  
  @override
  Map<String, dynamic>? toJson(PostState state) => state.toJson();

}

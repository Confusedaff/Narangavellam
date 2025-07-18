import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:insta_blocks/insta_blocks.dart';
import 'package:narangavellam/feed/bloc/feed_bloc.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:user_repository/user_repository.dart';

part 'user_profile_event.dart';
part 'user_profile_state.dart';

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  UserProfileBloc({
    required UserRepository userRepository,
    required PostsRepository postsRepository,
    String? userId,
    }) : _userRepository = userRepository,
        _postsRepository = postsRepository,
        _userId = userId ?? userRepository.currentUserId ?? '', 
        super(const UserProfileState.initial()){
          on<UserProfileSubscriptionRequested>(_onUserProfileSubscriptionRequested);
          on<UserProfilePostsCountSubscriptionRequested>(_onUserProfilePostsCountSubscriptionRequested);
          on<UserProfileFollowersCountSubscriptionRequested>(_onUserProfileFollowersCountSubscriptionRequested);
          on<UserProfileFollowingsCountSubscriptionRequested>(_onUserProfileFollowingsCountSubscriptionRequested);
          on<UserProfileFollowUserRequested>(_onUserProfileFollowUserRequested);
          on<UserProfileFetchFollowersRequested>(_onFollowersFetch);
          on<UserProfileFetchFollowingsRequested>(_onUserProfileFetchFollowingsRequested);
          on<UserProfileFollowersSubscriptionRequested>(_onFollowersSubscriptionRequested);
          on<UserProfileRemoveFollowerRequested>(_onUserProfileRemoveFollowerRequested);
          on<UserProfileUpdateRequested>(_onUserProfileUpdateRequested);
        }
  
  final String _userId;
  final UserRepository _userRepository;
  final PostsRepository _postsRepository;

  bool get isOwner => _userId == _userRepository.currentUserId;

  Stream<List<PostBlock>> userPosts({bool small = true}) {
  if (small) {
    return _postsRepository
        .postsOf(userId: _userId)
        .map((posts) => posts.map((e) => e.toPostSmallBlock).toList());
  }
  return _postsRepository
      .postsOf(userId: _userId)
      .map((posts) => posts.map((e) => e.toPostLargeBlock).toList());
}

  Stream<bool> followingStatus({String? followersId})=>
    _userRepository.followingStatus(userId: _userId).asBroadcastStream();


  Future<void> _onUserProfileSubscriptionRequested(
    UserProfileSubscriptionRequested event,
    Emitter<UserProfileState> emit,
  )async{
    await emit.forEach(isOwner ? _userRepository.user : _userRepository.profile(userId: _userId),
     onData: (user) => state.copyWith(user:user),
     );
  }

      Future<void> _onUserProfilePostsCountSubscriptionRequested(
      UserProfilePostsCountSubscriptionRequested event,
      Emitter<UserProfileState> emit,
    ) async{
    await emit.forEach(
      _postsRepository.postsAmountof(userId:_userId),
      onData: (postsCount) => state.copyWith(postsCount: postsCount),
    );
  }

  Future<void> _onUserProfileFollowingsCountSubscriptionRequested(
    UserProfileFollowingsCountSubscriptionRequested event,
    Emitter<UserProfileState> emit,
  ) async {
    await emit.forEach(
      _userRepository.followingsCountOf(userId: _userId),
      onData: (followingsCount) =>
        state.copyWith(followingsCount: followingsCount),
    );
  }

  Future<void> _onUserProfileFollowersCountSubscriptionRequested(
    UserProfileFollowersCountSubscriptionRequested event,
    Emitter<UserProfileState> emit,
  ) async {
    await emit.forEach(
      _userRepository.followersCountOf(userId: _userId),
      onData: (followersCount) =>
        state.copyWith(followersCount: followersCount),
    );
  }

  Future<void> _onUserProfileFollowUserRequested(
    UserProfileFollowUserRequested event,
    Emitter<UserProfileState> emit,
  ) async {
    try{
      await _userRepository.follow(followToId: event.userId ?? _userId);
    }catch(error,stackTrace){
      addError(error,stackTrace);
    }
  }

    Future<void> _onFollowersSubscriptionRequested(
      UserProfileFollowersSubscriptionRequested event,
      Emitter<UserProfileState> emit,
    ) async {
      try {
        final followers = await _userRepository.getFollowers(userId: event.userId);
        emit(state.copyWith(followers: followers));
      } catch (error, stackTrace) {
        addError(error, stackTrace);
      }
    }

    Future<void> _onFollowersFetch(
    UserProfileFetchFollowersRequested event,
    Emitter<UserProfileState> emit,
  ) async {
    try {
      final followers = await _userRepository.getFollowers(userId: _userId);
      emit(state.copyWith(followers: followers));
    } catch (error, stackTrace) {
      addError(error, stackTrace);
    }
  }


    Future<void> _onUserProfileFetchFollowingsRequested(
    UserProfileFetchFollowingsRequested event,
    Emitter<UserProfileState> emit,
    ) async {
    try {
      final followings = await _userRepository.getFollowings(userId: _userId);
      emit(state.copyWith(followings: followings));
    } catch (error, stackTrace) {
      addError(error, stackTrace);
    }
  }

   Future<void> _onUserProfileRemoveFollowerRequested(
    UserProfileRemoveFollowerRequested event,
    Emitter<UserProfileState> emit,
  ) async {
    try {
      await _userRepository.removeFollower(id: event.userId ?? _userId);
    } catch (error, stackTrace) {
      addError(error, stackTrace);
    }
  }

  Future<void> _onUserProfileUpdateRequested(
    UserProfileUpdateRequested event,
    Emitter<UserProfileState> emit,
    ) async {
   try {
      await _userRepository.updateUser(
      email: event.email,
      username: event.username,
      avatarUrl: event.avatarUrl,
      fullName: event.fullName,
      pushToken: event.pushToken,
    );

    emit(state.copyWith(status: UserProfileStatus.userUpdated));
    } catch (error, stackTrace) {
    addError(error, stackTrace);
    emit(state.copyWith(status: UserProfileStatus.userUpdateFailed));
    }
  }

}

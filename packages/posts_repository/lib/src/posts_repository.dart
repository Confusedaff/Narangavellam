import 'package:database_client/database_client.dart';
import 'package:shared/shared.dart';
import 'package:user_repository/src/models/user.dart';

/// {@template posts_repository}
/// A Very Good Project created by Very Good CLI.
/// {@endtemplate}
class PostsRepository extends PostsBaseRepository{
  /// {@macro posts_repository}
  const PostsRepository({required DatabaseClient databaseClient})
  :_databaseClient = databaseClient;
  
  final DatabaseClient _databaseClient;
  @override
  Stream<int> postsAmountof({required String userId})=>
    _databaseClient.postsAmountof(userId: userId);

  @override
  Future<Post?> createPost({
    required String id, 
    required String caption, 
    required String media,}) => 
    _databaseClient.createPost(id: id, caption: caption, media: media);
    
      @override
      Future<List<Post>> getPage({
        required int offset, 
        required int limit, 
        bool onlyReels = false,}) => 
        _databaseClient.getPage(
          offset: offset, 
          limit: limit,
          onlyReels: onlyReels,
          );

  @override
  Future<List<User>> getPostLikersInFollowings({
    required String postId,
    int limit = 3, 
    int offset = 0,}) =>
    _databaseClient.getPostLikersInFollowings(postId: postId,limit: limit);
    
  @override
  Stream<int> likesOf({required String id, bool post = true}) =>
  _databaseClient.likesOf(id: id,post: post);
      
  @override
  Stream<bool> isLiked({
  required String id,
  String? userId,
  bool post = true})=>
  _databaseClient.isLiked(id: id,post: post,userId: userId);
            
  @override
  Stream<int> commentsAmountOf({required String postId}) =>
    _databaseClient.commentsAmountOf(postId: postId);
}

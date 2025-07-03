import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:narangavellam/app/view/app.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:user_repository/user_repository.dart';

class MockUserRepository extends Mock implements UserRepository{}
class MockUser extends Mock implements User{}
class MockPostsRepository extends Mock implements PostsRepository{}

void main() {
  group('App', () {
    testWidgets('renders Scaffold', (tester) async {
      await tester.pumpWidget(
        App(
          user: MockUser(),
          userRepository: MockUserRepository(), 
          postsRepository: MockPostsRepository(),),
      );
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:narangavellam/app/view/app.dart';
import 'package:user_repository/user_repository.dart';

class MockUserRepository extends Mock implements UserRepository{}
class MockUser extends Mock implements User{}

void main() {
  group('App', () {
    testWidgets('renders Scaffold', (tester) async {
      await tester.pumpWidget(
        App(
          user: MockUser(),
          userRepository: MockUserRepository(),),
      );
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}

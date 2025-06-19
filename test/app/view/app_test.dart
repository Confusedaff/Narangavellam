import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
//import 'package:mocktail/mocktail.dart';
//import 'package:narangavellam/app/app.dart';
void main() {
  group('App', () {
    testWidgets('renders Scaffold', (tester) async {
      //await tester.pumpWidget(App(apiRepository: MockApiRepository()));
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}

// Basic Flutter widget test for Lyra

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lyra/app/app.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: LyraApp()));

    // Verify that the app renders (Home screen should show "Lyra" title)
    expect(find.text('Lyra'), findsOneWidget);
  });
}

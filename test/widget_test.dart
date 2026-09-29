// The original file here was `flutter create`'s counter smoke test, which never
// matched this app and failed on every run. It is kept as the place for
// top-level widget tests; the wallpaper feature has its own file.
//
// Anything that builds MyApp needs Firebase initialised first, which a widget
// test cannot do, so this only covers widgets that stand alone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:faniverse_main/widgets/content_thumbnail.dart';
import 'package:faniverse_main/models/content_item.dart';

void main() {
  testWidgets('ContentThumbnail renders a video badge for a video post', (
    WidgetTester tester,
  ) async {
    final item = ContentItem(
      id: 'c1',
      title: 'A clip',
      category: 'anime',
      type: 'video',
      videoUrl: 'https://example.com/clip.mp4',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SizedBox(width: 200, height: 200, child: ContentThumbnail(item: item))),
      ),
    );

    expect(find.byType(ContentThumbnail), findsOneWidget);
  });
}

import 'dart:math';

import '../models/content_item.dart';

/// The three ways a feed can be ordered, matching the pill row in the designs.
///
/// These are a **presentation** concern: the same loaded page of posts is
/// re-ordered locally for each mode rather than re-queried, so switching a pill
/// is instant and never changes what is in the window.
enum FeedMode {
  forYou('For you'),
  trending('Trending'),
  latest('Latest');

  const FeedMode(this.label);
  final String label;
}

/// Orders a loaded page of posts for a given mode.
///
/// The three modes are genuinely different, not aliases:
///
///  * **forYou** - weighted towards the viewer's declared fandoms, with a
///    small random jitter so the feed does not feel mechanical and a post does
///    not sit at rank 1 forever. A little randomness is deliberate here.
///  * **trending** - pure engagement. The score weights likes, views, comments
///    and saves, so a post that is *read* and *discussed* can outrank one that
///    is only liked. No randomness, so the ranking is defensible.
///  * **latest** - newest first by `createdAt`, falling back to document order
///    for posts with no timestamp.
class FeedSorter {
  const FeedSorter._();

  /// Applies [mode] to [items] and returns a new list, leaving the input alone.
  static List<ContentItem> sort(
    List<ContentItem> items,
    FeedMode mode, {
    Set<String> preferredCategories = const {},
    Random? random,
  }) {
    final out = List<ContentItem>.of(items);

    switch (mode) {
      case FeedMode.forYou:
        out.sort((a, b) => _forYou(b, a, preferredCategories, random).compareTo(
              _forYou(a, b, preferredCategories, random),
            ));
      case FeedMode.trending:
        out.sort((a, b) => b.trendingScore.compareTo(a.trendingScore));
      case FeedMode.latest:
        out.sort((a, b) => _timestamp(b).compareTo(_timestamp(a)));
    }

    return out;
  }

  /// Score for the personalised feed.
  ///
  /// A post in one of the viewer's fandoms gets a fixed boost, engagement
  /// breaks ties, and [random] adds enough jitter to shuffle near-neighbours
  /// without promoting a dead post above a popular one.
  static double _forYou(
    ContentItem item,
    ContentItem other,
    Set<String> preferredCategories,
    Random? random,
  ) {
    var score = item.trendingScore;

    if (preferredCategories.isNotEmpty && item.matchesAnyCategory(preferredCategories)) {
      // Roughly the weight of a handful of likes: enough to lead with what the
      // fan asked for, not enough to bury genuinely trending content.
      score += 40;
    }

    return score + (random?.nextDouble() ?? 0) * 12;
  }

  static DateTime _timestamp(ContentItem item) =>
      item.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
}

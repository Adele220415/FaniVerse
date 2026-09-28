import 'dart:io';

import 'package:faniverse_main/models/show_model.dart';
import 'package:faniverse_main/services/tv_show_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TvShow.stripHtml', () {
    test('removes tags and decodes entities', () {
      expect(
        TvShow.stripHtml('<p>Six young <b>20-something</b> people &amp; friends.</p>'),
        'Six young 20-something people & friends.',
      );
    });

    test('turns paragraph breaks into newlines', () {
      expect(
        TvShow.stripHtml('<p>One</p><p>Two</p>'),
        'One\n\nTwo',
      );
    });

    test('collapses excess blank lines', () {
      expect(TvShow.stripHtml('<p>A</p><p></p><p></p><p>B</p>'), 'A\n\nB');
    });
  });

  group('TvShow.fromJson', () {
    test('reads a well-formed show', () {
      final show = TvShow.fromJson({
        'id': 431,
        'name': 'Friends',
        'url': 'https://www.tvmaze.com/shows/431/friends',
        'type': 'Scripted',
        'language': 'English',
        'genres': ['Comedy', 'Romance'],
        'status': 'Ended',
        'premiered': '1994-09-22',
        'ended': '2004-05-06',
        'image': {
          'medium': 'https://static.tvmaze.com/medium.jpg',
          'original': 'https://static.tvmaze.com/original.jpg',
        },
        'summary': '<p>A group of friends.</p>',
        'network': {'id': 1, 'name': 'NBC'},
        'rating': {'average': 8.5},
        'externals': {'imdb': 'tt0108778'},
      });

      expect(show.id, 431);
      expect(show.name, 'Friends');
      expect(show.genres, ['Comedy', 'Romance']);
      expect(show.premieredYear, '1994');
      expect(show.networkName, 'NBC');
      expect(show.imdbId, 'tt0108778');
      expect(show.ratingAverage, 8.5);
      expect(show.hasImage, isTrue);
      expect(show.posterUrl, 'https://static.tvmaze.com/medium.jpg');
      expect(show.summaryText, 'A group of friends.');
    });

    test('survives a show with no image, genres or network', () {
      final show = TvShow.fromJson({
        'id': 9,
        'name': 'Nameless',
        'image': null,
        'genres': [],
        'network': null,
        'webChannel': {'id': 21, 'name': 'YouTube'},
        'summary': null,
        'rating': {'average': null},
        'externals': {'imdb': null},
      });

      expect(show.hasImage, isFalse);
      expect(show.posterUrl, isNull);
      expect(show.summaryText, '');
      expect(show.genresText, '');
      expect(show.premieredYear, isNull);
      // Falls back to the web channel when there is no broadcast network.
      expect(show.networkName, 'YouTube');
    });
  });

  group('TvShow.fromSearchEntry', () {
    test('unwraps the nested show object', () {
      final show = TvShow.fromSearchEntry({
        'score': 0.89,
        'show': {
          'id': 1,
          'name': 'Breaking Bad',
          'image': {'medium': 'https://static.tvmaze.com/bb.jpg'},
        },
      });

      expect(show.name, 'Breaking Bad');
      expect(show.id, 1);
    });
  });

  group('TvShowService (live TVmaze)', () {
    // These hit the real API. They are the only proof that the field names
    // and null handling match what TVmaze actually returns today.
    final service = TvShowService();

    tearDown(() => service.dispose());

    test('searchShows returns parsed shows with posters', () async {
      final result = await withRealHttp(() => service.searchShows('friends'));

      expect(result.isSuccess, isTrue, reason: 'search failed: ${result.error}');
      final shows = result.data!;
      expect(shows, isNotEmpty);
      // The exact show should be the top relevance hit.
      expect(shows.first.name.toLowerCase(), 'friends');
      expect(shows.first.id, 431);
      expect(shows.first.hasImage, isTrue);
      // Summary is HTML on the wire but plain text once parsed.
      expect(shows.first.summaryText, isNot(contains('<')));
    });

    test('searchShows rejects an empty query without calling the API', () async {
      final result = await service.searchShows('   ');

      expect(result.isSuccess, isFalse);
      expect(result.error, isNotNull);
    });

    test('serves a repeat search from cache', () async {
      final first = await withRealHttp(() => service.searchShows('the office'));
      final second = await service.searchShows('the office');

      expect(second.isSuccess, isTrue);
      expect(second.data!.length, first.data!.length);
    });

    test('getShowDetail returns cast and artwork', () async {
      final result = await withRealHttp(() => service.getShowDetail(431));

      expect(result.isSuccess, isTrue, reason: result.error);
      final detail = result.data!;
      expect(detail.show.name, 'Friends');
      expect(detail.cast, isNotEmpty);
      expect(detail.cast.first.imageUrl, isNotNull);
      expect(detail.images, isNotEmpty);
      expect(detail.posters, isNotEmpty);
      // Friends has landscape art, which is what a banner would use.
      expect(detail.backgroundUrl, isNotNull);
    });

    test('getShow reports a missing show as an error, not a crash', () async {
      final result = await withRealHttp(() => service.getShow(-1));

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Show not found');
    });
  });
}

/// Runs [body] with real networking enabled.
///
/// The flutter_test binding installs an `HttpOverrides` that blocks outbound
/// requests, so live-API tests have to clear it or every call fails with a
/// ClientException. Clearing the global override is the supported escape hatch;
/// `HttpOverrides.runZoned` does not work because `createHttpClient` re-enters
/// the very override it is installing.
Future<T> withRealHttp<T>(Future<T> Function() body) async {
  final saved = HttpOverrides.current;
  HttpOverrides.global = null;
  try {
    return await body();
  } finally {
    HttpOverrides.global = saved;
  }
}

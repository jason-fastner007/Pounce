import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pounce/core/settings.dart';
import 'package:pounce/core/store.dart';
import 'package:pounce/sc/models.dart';
import 'package:pounce/sc/soundcloud.dart';

void main() {
  group('SoundCloud client unit tests', () {
    late Store store;
    late Settings settings;

    setUp(() {
      store = Store.memory();
      settings = Settings(store);
      Track.drmPlayback = false;
    });

    tearDown(() {
      Track.drmPlayback = false;
    });

    test('clientId scrapes ID from JS bundle and caches it in Store', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString() == 'https://soundcloud.com/') {
          return http.Response(
            '<html><script src="https://a-v2.sndcdn.com/assets/123-abc.js"></script></html>',
            200,
          );
        } else if (request.url.toString() == 'https://a-v2.sndcdn.com/assets/123-abc.js') {
          return http.Response('console.log("hello"); client_id="12345678901234567890123456789012"', 200);
        }
        return http.Response('Not Found', 404);
      });

      final sc = SoundCloud(store, settings, client: mockClient);
      final cid = await sc.clientId();

      expect(cid, '12345678901234567890123456789012');
      expect(store.get<String>('sc.cid'), '12345678901234567890123456789012');
      expect(store.get<int>('sc.cidAt'), isNotNull);

      // Subsequent call should use cache without invoking network
      final cachedCid = await sc.clientId();
      expect(cachedCid, cid);
    });

    test('clientId throws ScException when client_id is not found', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString() == 'https://soundcloud.com/') {
          return http.Response('<html><script src="https://a-v2.sndcdn.com/assets/123.js"></script></html>', 200);
        }
        return http.Response('no client id here', 200);
      });

      final sc = SoundCloud(store, settings, client: mockClient);
      expect(() => sc.clientId(refresh: true), throwsA(isA<ScException>()));
    });

    test('searchTracks, searchPlaylists, searchAlbums, searchUsers and suggestions', () async {
      store.set('sc.cid', 'testcid123456789012345678901234');
      store.set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        expect(request.url.queryParameters['client_id'], 'testcid123456789012345678901234');
        expect(request.url.queryParameters['app_locale'], 'en');

        if (path == '/search/tracks') {
          return http.Response(
            jsonEncode({
              'collection': [
                {
                  'id': 101,
                  'title': 'Track 1',
                  'duration': 180000,
                  'user': {'id': 1, 'username': 'Artist 1'},
                }
              ],
              'next_href': 'https://api-v2.soundcloud.com/search/tracks?offset=30',
            }),
            200,
          );
        } else if (path == '/search/playlists_without_albums') {
          return http.Response(
            jsonEncode({
              'collection': [
                {
                  'id': 201,
                  'title': 'Playlist 1',
                  'user': {'id': 1, 'username': 'Artist 1'},
                  'tracks': [],
                }
              ],
            }),
            200,
          );
        } else if (path == '/search/albums') {
          return http.Response(
            jsonEncode({
              'collection': [
                {
                  'id': 301,
                  'title': 'Album 1',
                  'user': {'id': 1, 'username': 'Artist 1'},
                  'tracks': [],
                }
              ],
            }),
            200,
          );
        } else if (path == '/search/users') {
          return http.Response(
            jsonEncode({
              'collection': [
                {'id': 1, 'username': 'Artist 1'}
              ],
            }),
            200,
          );
        } else if (path == '/search/queries') {
          return http.Response(
            jsonEncode({
              'collection': [
                {'output': 'suggestion 1'},
                {'output': 'suggestion 2'}
              ],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final sc = SoundCloud(store, settings, client: mockClient);

      final tracksPage = await sc.searchTracks('techno');
      expect(tracksPage.items.length, 1);
      expect(tracksPage.items.first.title, 'Track 1');
      expect(tracksPage.next, 'https://api-v2.soundcloud.com/search/tracks?offset=30');

      final playlistsPage = await sc.searchPlaylists('house');
      expect(playlistsPage.items.first.title, 'Playlist 1');

      final albumsPage = await sc.searchAlbums('ambient');
      expect(albumsPage.items.first.title, 'Album 1');

      final usersPage = await sc.searchUsers('artist');
      expect(usersPage.items.first.username, 'Artist 1');

      final sug = await sc.suggestions('test');
      expect(sug, ['suggestion 1', 'suggestion 2']);
    });

    test('me, myLikes, myPlaylists, feed and selections', () async {
      store.set('sc.cid', 'testcid123456789012345678901234');
      store.set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        if (path == '/me') {
          return http.Response(jsonEncode({'id': 50, 'username': 'Me'}), 200);
        } else if (path == '/users/50/track_likes') {
          return http.Response(
            jsonEncode({
              'collection': [
                {
                  'track': {
                    'id': 111,
                    'title': 'Liked Track',
                    'duration': 120000,
                    'user': {'id': 1, 'username': 'Artist'},
                  }
                }
              ]
            }),
            200,
          );
        } else if (path == '/users/50/playlists_without_albums') {
          return http.Response(
            jsonEncode({
              'collection': [
                {
                  'id': 222,
                  'title': 'My Playlist',
                  'user': {'id': 1, 'username': 'Artist'},
                  'tracks': [],
                }
              ]
            }),
            200,
          );
        } else if (path == '/users/50/playlist_likes') {
          return http.Response(
            jsonEncode({
              'collection': [
                {
                  'playlist': {
                    'id': 223,
                    'title': 'Liked Playlist',
                    'user': {'id': 1, 'username': 'Artist'},
                    'tracks': [],
                  }
                }
              ]
            }),
            200,
          );
        } else if (path == '/stream') {
          return http.Response(
            jsonEncode({
              'collection': [
                {
                  'track': {
                    'id': 333,
                    'title': 'Feed Track',
                    'duration': 150000,
                    'user': {'id': 1, 'username': 'Artist'},
                  }
                }
              ]
            }),
            200,
          );
        } else if (path == '/mixed-selections') {
          return http.Response(
            jsonEncode({
              'collection': [
                {
                  'title': 'Charts',
                  'items': {
                    'collection': [
                      {
                        'kind': 'playlist',
                        'id': 444,
                        'title': 'Top 50',
                        'user': {'id': 1, 'username': 'SC'},
                        'tracks': [],
                      }
                    ]
                  }
                }
              ]
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final sc = SoundCloud(store, settings, client: mockClient);

      final userMe = await sc.me();
      expect(userMe.id, 50);
      expect(userMe.username, 'Me');

      final likes = await sc.myLikes(50);
      expect(likes.length, 1);
      expect(likes.first.title, 'Liked Track');

      final playlists = await sc.myPlaylists(50);
      expect(playlists.length, 2);

      final feed = await sc.feed();
      expect(feed.first.title, 'Feed Track');

      final selections = await sc.selections();
      expect(selections.length, 1);
      expect(selections.first.title, 'Charts');
      expect(selections.first.playlists.first.title, 'Top 50');
    });

    test('progressiveMp3 stream selection', () async {
      store.set('sc.cid', 'testcid123456789012345678901234');
      store.set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);

      final mockClient = MockClient((request) async {
        if (request.url.path == '/transcodings/prog') {
          return http.Response(jsonEncode({'url': 'https://cdn/audio.mp3'}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final sc = SoundCloud(store, settings, client: mockClient);

      final track = Track.fromJson({
        'id': 777,
        'title': 'Prog Track',
        'duration': 120000,
        'user': {'id': 1, 'username': 'Artist'},
        'track_authorization': 'auth',
        'media': {
          'transcodings': [
            {
              'url': 'https://api-v2.soundcloud.com/transcodings/prog',
              'preset': 'mp3_128k',
              'snipped': false,
              'format': {'protocol': 'progressive', 'mime_type': 'audio/mpeg'},
            }
          ]
        }
      });

      final progUrl = await sc.progressiveMp3(track);
      expect(progUrl, 'https://cdn/audio.mp3');
    });

    test('tracks handles batching (>50 tracks)', () async {
      store.set('sc.cid', 'testcid123456789012345678901234');
      store.set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);

      final requestedBatches = <String>[];
      final mockClient = MockClient((request) async {
        final idsParam = request.url.queryParameters['ids']!;
        requestedBatches.add(idsParam);

        final idList = idsParam.split(',').map(int.parse).toList();
        final responseList = idList
            .map(
              (id) => {
                'id': id,
                'title': 'Track $id',
                'duration': 120000,
                'user': {'id': 1, 'username': 'User'},
              },
            )
            .toList();

        return http.Response(jsonEncode(responseList), 200);
      });

      final sc = SoundCloud(store, settings, client: mockClient);
      final ids = List.generate(75, (i) => i + 1);
      final result = await sc.tracks(ids);

      expect(result.length, 75);
      expect(requestedBatches.length, 2);
      expect(requestedBatches[0].split(',').length, 50);
      expect(requestedBatches[1].split(',').length, 25);
    });

    test('playlist resolves stub tracks', () async {
      store.set('sc.cid', 'testcid123456789012345678901234');
      store.set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);

      final mockClient = MockClient((request) async {
        if (request.url.path == '/playlists/10') {
          return http.Response(
            jsonEncode({
              'id': 10,
              'title': 'My Playlist',
              'user': {'id': 1, 'username': 'User'},
              'tracks': [
                {'id': 101}, // stub track
                {
                  'id': 102,
                  'title': 'Full Track 102',
                  'duration': 200000,
                  'user': {'id': 1, 'username': 'User'},
                },
              ],
            }),
            200,
          );
        } else if (request.url.path == '/tracks') {
          return http.Response(
            jsonEncode([
              {
                'id': 101,
                'title': 'Resolved Stub 101',
                'duration': 150000,
                'user': {'id': 1, 'username': 'User'},
              }
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final sc = SoundCloud(store, settings, client: mockClient);
      final pl = await sc.playlist(10);

      expect(pl.tracks.length, 2);
      expect(pl.tracks[0].title, 'Resolved Stub 101');
      expect(pl.tracks[1].title, 'Full Track 102');
    });

    test('resolve handles track, playlist and user URLs', () async {
      store.set('sc.cid', 'testcid123456789012345678901234');
      store.set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);

      final mockClient = MockClient((request) async {
        final targetUrl = request.url.queryParameters['url'];
        if (targetUrl == 'https://soundcloud.com/artist/track1') {
          return http.Response(
            jsonEncode({
              'kind': 'track',
              'id': 500,
              'title': 'Resolved Track',
              'duration': 100000,
              'user': {'id': 1, 'username': 'Artist'},
            }),
            200,
          );
        } else if (targetUrl == 'https://soundcloud.com/artist/sets/set1') {
          return http.Response(
            jsonEncode({
              'kind': 'playlist',
              'id': 600,
            }),
            200,
          );
        } else if (request.url.path == '/playlists/600') {
          return http.Response(
            jsonEncode({
              'id': 600,
              'title': 'Resolved Playlist',
              'user': {'id': 1, 'username': 'Artist'},
              'tracks': [],
            }),
            200,
          );
        } else if (targetUrl == 'https://soundcloud.com/artist') {
          return http.Response(
            jsonEncode({'kind': 'user', 'id': 1, 'username': 'Artist'}),
            200,
          );
        }
        return http.Response(jsonEncode({'kind': 'unknown'}), 200);
      });

      final sc = SoundCloud(store, settings, client: mockClient);

      final trackRes = await sc.resolve('https://soundcloud.com/artist/track1');
      expect(trackRes, isA<ResolvedTrack>());
      expect((trackRes as ResolvedTrack).track.title, 'Resolved Track');

      final playlistRes = await sc.resolve('https://soundcloud.com/artist/sets/set1');
      expect(playlistRes, isA<ResolvedPlaylist>());

      final userRes = await sc.resolve('https://soundcloud.com/artist');
      expect(userRes, isA<ResolvedUser>());

      final nullRes = await sc.resolve('https://soundcloud.com/unknown');
      expect(nullRes, null);
    });

    test('stream URL resolution with transcodings and caching', () async {
      Track.drmPlayback = true;
      store.set('sc.cid', 'testcid123456789012345678901234');
      store.set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);

      final mockClient = MockClient((request) async {
        if (request.url.path == '/transcodings/hls') {
          return http.Response(
            jsonEncode({
              'url': 'https://stream.media.sndcdn.com/stream.m3u8',
              'licenseAuthToken': 'jwt_token_123',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final sc = SoundCloud(store, settings, client: mockClient);

      final track = Track.fromJson({
        'id': 999,
        'title': 'Stream Test Track',
        'duration': 180000,
        'track_authorization': 'auth_123',
        'user': {'id': 1, 'username': 'Artist'},
        'secret_token': 'secret123',
        'media': {
          'transcodings': [
            {
              'url': 'https://api-v2.soundcloud.com/transcodings/hls',
              'preset': 'aac_160k',
              'duration': 180000,
              'snipped': false,
              'format': {'protocol': 'ctr-encrypted-hls', 'mime_type': 'audio/mp4; codecs="mp4a.40.2"'},
            }
          ]
        }
      });

      final info = await sc.stream(track);
      expect(info.url, 'https://stream.media.sndcdn.com/stream.m3u8');
      expect(info.hls, isTrue);
      expect(info.drm, isTrue);
      expect(info.licenseToken, 'jwt_token_123');
      expect(info.label, contains('AAC'));

      // Re-querying should return cached future
      final infoCached = await sc.stream(track);
      expect(infoCached.url, info.url);
    });

    test('waveform caching and error handling', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('waveform.json')) {
          return http.Response(jsonEncode({'height': 100, 'samples': [0, 50, 100]}), 200);
        }
        return http.Response('Error', 500);
      });

      final sc = SoundCloud(store, settings, client: mockClient);

      final trackWithWave = Track.fromJson({
        'id': 123,
        'waveform_url': 'https://wave.sndcdn.com/waveform.png',
        'user': {'id': 1, 'username': 'Artist'},
      });

      final samples = await sc.waveform(trackWithWave);
      expect(samples, [0.0, 0.5, 1.0]);

      final trackNoWave = Track.fromJson({
        'id': 124,
        'waveform_url': 'https://wave.sndcdn.com/fail.png',
        'user': {'id': 1, 'username': 'Artist'},
      });

      final emptySamples = await sc.waveform(trackNoWave);
      expect(emptySamples, isEmpty);
    });

    test('range fetches bytes and handles server response', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['Range'], 'bytes=0-4');
        return http.Response.bytes(Uint8List.fromList([1, 2, 3, 4, 5]), 206);
      });

      final sc = SoundCloud(store, settings, client: mockClient);
      final bytes = await sc.range('https://cdn.com/audio.mp3', 0, 4);

      expect(bytes, Uint8List.fromList([1, 2, 3, 4, 5]));
    });

    test('range cuts bytes if server returns 200 OK full response', () async {
      final mockClient = MockClient((request) async {
        // Server ignores Range and returns full 10-byte file with status 200
        return http.Response.bytes(Uint8List.fromList([10, 20, 30, 40, 50, 60, 70, 80, 90, 100]), 200);
      });

      final sc = SoundCloud(store, settings, client: mockClient);
      final bytes = await sc.range('https://cdn.com/audio.mp3', 2, 5);

      expect(bytes, [30, 40, 50, 60]);
    });

    test('user, userTracks, userTopTracks and userPlaylists', () async {
      store.set('sc.cid', 'testcid123456789012345678901234');
      store.set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        if (path == '/users/42') {
          return http.Response(jsonEncode({'id': 42, 'username': 'Artist 42'}), 200);
        } else if (path == '/users/42/tracks') {
          return http.Response(
            jsonEncode({
              'collection': [
                {
                  'id': 1001,
                  'title': 'User Track 1',
                  'duration': 200000,
                  'user': {'id': 42, 'username': 'Artist 42'},
                }
              ]
            }),
            200,
          );
        } else if (path == '/users/42/toptracks') {
          return http.Response(
            jsonEncode({
              'collection': [
                {
                  'id': 1002,
                  'title': 'Top Track 1',
                  'duration': 180000,
                  'user': {'id': 42, 'username': 'Artist 42'},
                }
              ]
            }),
            200,
          );
        } else if (path == '/users/42/playlists_without_albums') {
          return http.Response(
            jsonEncode({
              'collection': [
                {
                  'id': 2001,
                  'title': 'User Playlist 1',
                  'user': {'id': 42, 'username': 'Artist 42'},
                  'tracks': [],
                }
              ]
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final sc = SoundCloud(store, settings, client: mockClient);

      final u = await sc.user(42);
      expect(u.id, 42);
      expect(u.username, 'Artist 42');

      final trs = await sc.userTracks(42);
      expect(trs.items.single.title, 'User Track 1');

      final topTrs = await sc.userTopTracks(42);
      expect(topTrs.items.single.title, 'Top Track 1');

      final pls = await sc.userPlaylists(42);
      expect(pls.items.single.title, 'User Playlist 1');
    });

    test('setLiked mobile API fallback (without logged in auth throws 401)', () async {
      store.set('sc.cid', 'testcid123456789012345678901234');
      store.set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);

      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final sc = SoundCloud(store, settings, client: mockClient);
      final track = Track.fromJson({
        'id': 888,
        'title': 'Track 888',
        'user': {'id': 1, 'username': 'Artist'},
      });

      expect(() => sc.setLiked(track, true), throwsA(isA<ScException>()));
    });

    test('HTTP error codes like 451 (blocked) throwing ScException', () async {
      store.set('sc.cid', 'testcid123456789012345678901234');
      store.set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);

      final mockClient = MockClient((request) async {
        if (request.url.path == '/tracks/9999') {
          return http.Response('Blocked content', 451);
        }
        return http.Response('Not found', 404);
      });

      final sc = SoundCloud(store, settings, client: mockClient);

      expect(() => sc.track(9999), throwsA(isA<ScException>()));
    });
  });
}

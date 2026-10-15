import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pounce/core/settings.dart';
import 'package:pounce/core/store.dart';
import 'package:pounce/sc/auth.dart';
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

    test('user, userTracks, userTopTracks, userPlaylists and related endpoints', () async {
      store.set('sc.cid', 'testcid123456789012345678901234');
      store.set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        if (path == '/users/99') {
          return http.Response(jsonEncode({'id': 99, 'username': 'Artist99'}), 200);
        } else if (path == '/users/99/tracks') {
          return http.Response(
            jsonEncode({
              'collection': [
                {
                  'id': 901,
                  'title': 'User Track 1',
                  'duration': 120000,
                  'user': {'id': 99, 'username': 'Artist99'},
                }
              ]
            }),
            200,
          );
        } else if (path == '/users/99/toptracks') {
          return http.Response(
            jsonEncode({
              'collection': [
                {
                  'id': 902,
                  'title': 'User Top Track',
                  'duration': 180000,
                  'user': {'id': 99, 'username': 'Artist99'},
                }
              ]
            }),
            200,
          );
        } else if (path == '/users/99/playlists_without_albums') {
          return http.Response(
            jsonEncode({
              'collection': [
                {
                  'id': 903,
                  'title': 'User Playlist',
                  'user': {'id': 99, 'username': 'Artist99'},
                  'tracks': [],
                }
              ]
            }),
            200,
          );
        } else if (path == '/tracks/901/related') {
          return http.Response(
            jsonEncode({
              'collection': [
                {
                  'id': 905,
                  'title': 'Related Track',
                  'duration': 200000,
                  'user': {'id': 99, 'username': 'Artist99'},
                }
              ]
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final sc = SoundCloud(store, settings, client: mockClient);

      final u = await sc.user(99);
      expect(u.id, 99);
      expect(u.username, 'Artist99');

      final uTracks = await sc.userTracks(99);
      expect(uTracks.items.first.title, 'User Track 1');

      final uTop = await sc.userTopTracks(99);
      expect(uTop.items.first.title, 'User Top Track');

      final uPlaylists = await sc.userPlaylists(99);
      expect(uPlaylists.items.first.title, 'User Playlist');

      final rel = await sc.related(901);
      expect(rel.first.title, 'Related Track');
    });

    test('setLiked in web client mode and mobile client mode', () async {
      store.set('sc.cid', 'testcid123456789012345678901234');
      store.set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);

      final webRequests = <String>[];
      final mobileRequests = <String>[];

      final mockClient = MockClient((request) async {
        if (request.url.host == 'api-v2.soundcloud.com') {
          webRequests.add('${request.method} ${request.url.path}');
          return http.Response('', 200);
        } else if (request.url.host == 'api-mobile.soundcloud.com') {
          mobileRequests.add('${request.method} ${request.url.path}');
          return http.Response('', 200);
        }
        return http.Response('Not Found', 404);
      });

      final sc = SoundCloud(store, settings, client: mockClient);
      final auth = ScAuth(store, mockClient, sc.wrap);
      sc.auth = auth;

      final testTrack = Track.fromJson({
        'id': 1234,
        'title': 'Like Test Track',
        'duration': 120000,
        'user': {'id': 1, 'username': 'Artist'},
      });

      // 1) Web Client mode
      store.set('auth.client', 'WEB_CLIENT_ID');
      store.set('auth.access', 'web_access_token');
      auth.setMe(const ScUser(id: 42, username: 'WebUser'));

      await sc.setLiked(testTrack, true);
      expect(webRequests.last, 'PUT /users/42/track_likes/1234');

      await sc.setLiked(testTrack, false);
      expect(webRequests.last, 'DELETE /users/42/track_likes/1234');

      // 2) Mobile Client mode (app client without web client override)
      store.set('auth.client', null);
      await sc.setLiked(testTrack, true);
      expect(mobileRequests.last, 'POST /likes/tracks/create');

      await sc.setLiked(testTrack, false);
      expect(mobileRequests.last, 'POST /likes/tracks/delete');
    });

    test('HTTP 401/403 retry logic and ScException on non-200 responses', () async {
      store.set('sc.cid', 'oldcid123456789012345678901234');
      store.set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);

      var attempts = 0;
      final mockClient = MockClient((request) async {
        attempts++;
        if (request.url.path == '/tracks/555') {
          if (attempts == 1) {
            // First attempt fails with 401
            return http.Response('Unauthorized', 401);
          }
          // Second attempt with scraped client_id succeeds
          return http.Response(
            jsonEncode({
              'id': 555,
              'title': 'Retried Track',
              'duration': 120000,
              'user': {'id': 1, 'username': 'User'},
            }),
            200,
          );
        } else if (request.url.path == '/tracks/999') {
          return http.Response('Forbidden Error', 403);
        } else if (request.url.toString() == 'https://soundcloud.com/') {
          return http.Response(
            '<html><script src="https://a-v2.sndcdn.com/assets/new.js"></script></html>',
            200,
          );
        } else if (request.url.toString() == 'https://a-v2.sndcdn.com/assets/new.js') {
          return http.Response('client_id="newcid12345678901234567890123456"', 200);
        }
        return http.Response('Not Found', 404);
      });

      final sc = SoundCloud(store, settings, client: mockClient);

      final track = await sc.track(555);
      expect(track.title, 'Retried Track');
      expect(attempts, 4); // attempt 1 -> 401, scrape page -> 200, scrape js -> 200, attempt 2 -> 200

      expect(() => sc.track(999), throwsA(isA<ScException>().having((e) => e.status, 'status', 403)));
    });

    test('stream errors for blocked tracks or missing transcodings', () async {
      store.set('sc.cid', 'testcid123456789012345678901234');
      store.set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);

      final mockClient = MockClient((request) async {
        if (request.url.path == '/transcodings/fail') {
          return http.Response('Not Found', 404);
        }
        return http.Response('Not Found', 404);
      });

      final sc = SoundCloud(store, settings, client: mockClient);

      final blockedTrack = Track.fromJson({
        'id': 1,
        'title': 'Blocked Track',
        'duration': 100000,
        'policy': 'BLOCK',
        'track_authorization': 'auth_123',
        'user': {'id': 1, 'username': 'Artist'},
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

      expect(
        () => sc.stream(blockedTrack),
        throwsA(isA<ScException>().having((e) => e.status, 'status', 451)),
      );

      final noStreamTrack = Track.fromJson({
        'id': 2,
        'title': 'No Stream Track',
        'duration': 100000,
        'user': {'id': 1, 'username': 'Artist'},
        'media': {
          'transcodings': [
            {
              'url': 'https://api-v2.soundcloud.com/transcodings/fail',
              'preset': 'mp3_128k',
              'snipped': false,
              'format': {'protocol': 'progressive', 'mime_type': 'audio/mpeg'},
            }
          ]
        }
      });

      expect(
        () => sc.stream(noStreamTrack),
        throwsA(isA<ScException>().having((e) => e.status, 'status', 404)),
      );
    });

    test('StreamInfo.label formatting and stream ranking options', () async {
      expect(
        const StreamInfo('https://stream', hls: true, live: true).label,
        'LIVE · HLS',
      );
      expect(
        const StreamInfo('https://stream', hls: false, mime: 'audio/mp4', preset: 'aac_160k').label,
        'AAC · 160k · PROG',
      );
      expect(
        const StreamInfo('https://stream', hls: true, mime: 'audio/ogg', preset: 'opus_64k', licenseToken: 'token').label,
        'OPUS · 64k · HLS · DRM',
      );
      expect(
        const StreamInfo('https://stream', hls: false, mime: 'audio/mpeg', preset: 'mp3_128k').label,
        'MP3 · 128k · PROG',
      );

      store.set('sc.cid', 'testcid123456789012345678901234');
      store.set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        if (path == '/transcodings/aac96') {
          return http.Response(jsonEncode({'url': 'https://cdn/aac96.m3u8'}), 200);
        } else if (path == '/transcodings/prog') {
          return http.Response(jsonEncode({'url': 'https://cdn/prog.mp3'}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final sc = SoundCloud(store, settings, client: mockClient);

      final multiTrack = Track.fromJson({
        'id': 3333,
        'title': 'Multi Stream Track',
        'duration': 120000,
        'track_authorization': 'auth',
        'user': {'id': 1, 'username': 'Artist'},
        'media': {
          'transcodings': [
            {
              'url': 'https://api-v2.soundcloud.com/transcodings/aac96',
              'preset': 'aac_96k',
              'snipped': false,
              'format': {'protocol': 'hls', 'mime_type': 'audio/mp4; codecs="mp4a.40.2"'},
            },
            {
              'url': 'https://api-v2.soundcloud.com/transcodings/prog',
              'preset': 'mp3_128k',
              'snipped': false,
              'format': {'protocol': 'progressive', 'mime_type': 'audio/mpeg'},
            },
          ]
        }
      });

      // Saver quality should prefer aac_96k over progressive mp3
      settings.quality = StreamQuality.saver;
      final saverStream = await sc.stream(multiTrack);
      expect(saverStream.preset, 'aac_96k');

      // Fast mode should prefer progressive mp3
      final fastStream = await sc.stream(multiTrack, fast: true);
      expect(fastStream.preset, 'mp3_128k');
    });

    test('Track, ScPlaylist, ScUser and Transcoding model getters and methods', () {
      final user = ScUser.fromJson({
        'id': 10,
        'username': 'TestArtist',
        'avatar_url': 'https://img/avatar.jpg',
        'followers_count': 500,
        'track_count': 20,
        'description': 'Bio',
        'city': 'Berlin',
        'verified': true,
        'visuals': {
          'visuals': [
            {'visual_url': 'https://img/banner.jpg'}
          ]
        }
      });

      expect(user.id, 10);
      expect(user.username, 'TestArtist');
      expect(user.bannerUrl, 'https://img/banner.jpg');
      expect(user.toJson()['id'], 10);

      final trackLive = Track.fromJson({
        'id': 101,
        'title': 'Live Radio Station',
        'duration': 0,
        'kf_live_url': 'https://stream.radio.com/live',
        'user': user.toJson(),
      });

      expect(trackLive.isLive, isTrue);
      expect(trackLive.isStub, isFalse);

      final trackBlocked = Track.fromJson({
        'id': 102,
        'title': 'Blocked Song',
        'duration': 180000,
        'policy': 'BLOCK',
        'user': user.toJson(),
      });

      expect(trackBlocked.isBlocked, isTrue);
      expect(trackBlocked.playable, isFalse);

      final trackProtected = Track.fromJson({
        'id': 103,
        'title': 'DRM Song',
        'duration': 200000,
        'user': user.toJson(),
        'media': {
          'transcodings': [
            {
              'url': 'https://stream/drm',
              'preset': 'aac_160k',
              'snipped': false,
              'format': {'protocol': 'ctr-encrypted-hls', 'mime_type': 'audio/mp4'},
            }
          ]
        }
      });

      expect(trackProtected.isProtected, isTrue);
      Track.drmPlayback = false;
      expect(trackProtected.playable, isFalse);
      Track.drmPlayback = true;
      expect(trackProtected.playable, isTrue);

      final trackPreview = Track.fromJson({
        'id': 104,
        'title': 'Preview Song',
        'duration': 30000,
        'policy': 'SNIP',
        'user': user.toJson(),
      });

      expect(trackPreview.isPreview, isTrue);

      final trackArt = Track.fromJson({
        'id': 105,
        'title': 'Art Song',
        'duration': 150000,
        'artwork_url': 'https://img/cover-large.jpg',
        'publisher_metadata': {'artist': 'Label Artist'},
        'user': user.toJson(),
      });

      expect(trackArt.art('t300x300'), 'https://img/cover-t300x300.jpg');
      expect(trackArt.artist, 'Label Artist');
      expect(trackArt == Track(id: 105, title: '', user: user, durationMs: 0), isTrue);
      expect(trackArt.hashCode, 105.hashCode);
      expect(trackArt.toJson()['publisher_metadata']['artist'], 'Label Artist');

      final playlist = ScPlaylist.fromJson({
        'id': 500,
        'title': 'Cool Playlist',
        'user': user.toJson(),
        'calculated_artwork_url': 'https://img/playlist-original.jpg',
        'track_count': 1,
        'is_album': true,
        'description': 'My Album',
        'tracks': [trackArt.toJson()],
      });

      expect(playlist.isAlbum, isTrue);
      expect(playlist.art('t500x500'), 'https://img/playlist-t500x500.jpg');

      final copiedPlaylist = playlist.copyWith(tracks: []);
      expect(copiedPlaylist.tracks, isEmpty);
      expect(copiedPlaylist.id, 500);

      final tc = Transcoding.fromJson({
        'url': 'https://stream/tc',
        'preset': 'aac_160k',
        'snipped': false,
        'format': {'protocol': 'hls', 'mime_type': 'audio/mp4'},
      });

      expect(tc.isHls, isTrue);
      expect(tc.isEncrypted, isFalse);
      expect(tc.toJson()['preset'], 'aac_160k');
    });
  });
}

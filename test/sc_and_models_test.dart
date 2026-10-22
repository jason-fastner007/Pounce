import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pounce/core/settings.dart';
import 'package:pounce/core/store.dart';
import 'package:pounce/sc/auth.dart';
import 'package:pounce/sc/models.dart';
import 'package:pounce/sc/soundcloud.dart';

void main() {
  group('SoundCloud Models Unit Tests', () {
    test('Transcoding model serialization and flags', () {
      final json = {
        'url': 'https://api.com/trans',
        'preset': 'mp3_0_0',
        'snipped': true,
        'format': {'protocol': 'ctr-encrypted-hls', 'mime_type': 'audio/mp4'},
      };

      final tc = Transcoding.fromJson(json);
      expect(tc.url, 'https://api.com/trans');
      expect(tc.preset, 'mp3_0_0');
      expect(tc.snipped, isTrue);
      expect(tc.isHls, isFalse); // protocol is ctr-encrypted-hls, not hls
      expect(tc.isEncrypted, isTrue);

      final serialized = tc.toJson();
      expect(serialized['url'], tc.url);
      expect(serialized['preset'], tc.preset);
      expect(serialized['snipped'], isTrue);
      expect(serialized['format'], {'protocol': 'ctr-encrypted-hls', 'mime_type': 'audio/mp4'});
    });

    test('ScUser model fromJson and toJson', () {
      final jsonWithBanner = {
        'id': 42,
        'username': 'testuser',
        'avatar_url': 'https://img/avatar.jpg',
        'followers_count': 100,
        'track_count': 5,
        'description': 'bio',
        'city': 'Berlin',
        'verified': true,
        'visuals': {
          'visuals': [
            {'visual_url': 'https://img/banner.jpg'}
          ]
        }
      };

      final user = ScUser.fromJson(jsonWithBanner);
      expect(user.id, 42);
      expect(user.username, 'testuser');
      expect(user.avatarUrl, 'https://img/avatar.jpg');
      expect(user.followers, 100);
      expect(user.trackCount, 5);
      expect(user.description, 'bio');
      expect(user.city, 'Berlin');
      expect(user.verified, isTrue);
      expect(user.bannerUrl, 'https://img/banner.jpg');

      final serialized = user.toJson();
      expect(serialized['id'], 42);
      expect(serialized['username'], 'testuser');
      expect(serialized['avatar_url'], 'https://img/avatar.jpg');
      expect(serialized['followers_count'], 100);
      expect(serialized['track_count'], 5);
      expect(serialized['verified'], isTrue);
    });

    test('Track model flags, DRM and art fallback', () {
      final jsonTrack = {
        'id': 10,
        'title': 'Awesome Track',
        'user': {'id': 1, 'username': 'Artist'},
        'full_duration': 240000,
        'artwork_url': 'https://img/art-large.jpg',
        'policy': 'BLOCK',
        'publisher_metadata': {'artist': 'Label Artist'},
        'media': {
          'transcodings': [
            {
              'url': 'https://api/hls',
              'preset': 'aac',
              'format': {'protocol': 'ctr-encrypted-hls', 'mime_type': 'audio/mp4'},
              'snipped': false,
            }
          ]
        }
      };

      final track = Track.fromJson(jsonTrack);
      expect(track.id, 10);
      expect(track.title, 'Awesome Track');
      expect(track.artist, 'Label Artist');
      expect(track.isBlocked, isTrue);
      expect(track.isProtected, isTrue);
      expect(track.isLive, isFalse);
      expect(track.isStub, isFalse);

      Track.drmPlayback = false;
      expect(track.playable, isFalse); // blocked and no DRM

      final liveTrack = Track(
        id: 11,
        title: 'Radio Station',
        user: const ScUser(id: 2, username: 'Radio'),
        durationMs: 0,
        streamUrl: 'https://radio.stream/live',
      );
      expect(liveTrack.isLive, isTrue);
      expect(liveTrack.playable, isTrue);

      final stubTrack = const Track(
        id: 12,
        title: '',
        user: ScUser(id: 0, username: ''),
        durationMs: 0,
      );
      expect(stubTrack.isStub, isTrue);

      // Artwork sizing
      expect(track.art('t200x200'), 'https://img/art-t200x200.jpg');

      final trackNoArt = Track(
        id: 13,
        title: 'No Art',
        user: const ScUser(id: 3, username: 'Artist', avatarUrl: 'https://img/avatar-large.jpg'),
        durationMs: 100000,
      );
      expect(trackNoArt.art('t500x500'), 'https://img/avatar-t500x500.jpg');

      // Equality and hashCode
      final trackSameId = Track(
        id: 10,
        title: 'Other Title',
        user: const ScUser(id: 1, username: 'Artist'),
        durationMs: 100,
      );
      expect(track, equals(trackSameId));
      expect(track.hashCode, trackSameId.hashCode);

      // Serialization
      final serialized = liveTrack.toJson();
      expect(serialized['id'], 11);
      expect(serialized['kf_live_url'], 'https://radio.stream/live');
    });

    test('ScPlaylist art fallback and copyWith', () {
      final user = const ScUser(id: 1, username: 'User', avatarUrl: 'https://img/user-large.jpg');
      final track1 = Track(
        id: 101,
        title: 'Track 1',
        user: user,
        durationMs: 1000,
        artworkUrl: 'https://img/track1-large.jpg',
      );

      final playlistWithoutArt = ScPlaylist(
        id: 1,
        title: 'Playlist 1',
        user: user,
        tracks: [track1],
      );

      expect(playlistWithoutArt.art('t300x300'), 'https://img/track1-t300x300.jpg');

      final playlistWithArt = playlistWithoutArt.copyWith(
        tracks: [],
      );
      expect(playlistWithArt.art('t300x300'), 'https://img/user-t300x300.jpg');
    });

    test('sized helper correctly formats URLs', () {
      expect(sized('https://img/art-large.jpg', 't200x200'), 'https://img/art-t200x200.jpg');
      expect(sized('https://img/art-t500x500.png', 'original'), 'https://img/art-original.png');
      expect(sized(null, 't500x500'), isNull);
    });
  });

  group('SoundCloud Client Extended Unit Tests', () {
    late Store store;
    late Settings settings;

    setUp(() {
      store = Store.memory();
      settings = Settings(store);
      store.set('sc.cid', 'testcid123456789012345678901234');
      store.set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);
    });

    test('setLiked calls Web client API or Mobile client API', () async {
      var mobileCalled = false;
      var webCalled = false;

      final mockClient = MockClient((request) async {
        if (request.url.host == 'api-mobile.soundcloud.com') {
          mobileCalled = true;
          return http.Response('', 200);
        } else if (request.url.path.contains('/track_likes/')) {
          webCalled = true;
          return http.Response('', 200);
        }
        return http.Response('Not Found', 404);
      });

      store.set('auth.access', 'valid_access_token');
      final sc = SoundCloud(store, settings, client: mockClient);
      final mobileAuth = ScAuth(store, mockClient, sc.wrap);
      sc.auth = mobileAuth;

      final track = Track(
        id: 55,
        title: 'Like Test Track',
        user: const ScUser(id: 1, username: 'User'),
        durationMs: 100000,
      );

      // Mobile client flow (no web client set)
      await sc.setLiked(track, true);
      expect(mobileCalled, isTrue);

      // Web auth client flow
      store.set('auth.client', 'web_client_id');
      final webAuth = ScAuth(store, mockClient, sc.wrap)..me = const ScUser(id: 99, username: 'WebUser');
      sc.auth = webAuth;

      await sc.setLiked(track, true);
      expect(webCalled, isTrue);
    });

    test('userTracks, userTopTracks, userPlaylists, track and next pagination', () async {
      final mockClient = MockClient((request) async {
        final path = request.url.path;
        if (path == '/users/10/tracks') {
          return http.Response(
            jsonEncode({
              'collection': [
                {
                  'id': 1,
                  'title': 'User Track 1',
                  'duration': 100000,
                  'user': {'id': 10, 'username': 'Artist'},
                }
              ],
              'next_href': 'https://api-v2.soundcloud.com/users/10/tracks?offset=20',
            }),
            200,
          );
        } else if (path == '/users/10/toptracks') {
          return http.Response(
            jsonEncode({
              'collection': [
                {
                  'id': 2,
                  'title': 'Top Track 1',
                  'duration': 100000,
                  'user': {'id': 10, 'username': 'Artist'},
                }
              ],
            }),
            200,
          );
        } else if (path == '/users/10/playlists_without_albums') {
          return http.Response(
            jsonEncode({
              'collection': [
                {
                  'id': 3,
                  'title': 'User Playlist 1',
                  'user': {'id': 10, 'username': 'Artist'},
                  'tracks': [],
                }
              ],
            }),
            200,
          );
        } else if (path == '/tracks/500') {
          return http.Response(
            jsonEncode({
              'id': 500,
              'title': 'Single Track 500',
              'duration': 120000,
              'user': {'id': 10, 'username': 'Artist'},
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final sc = SoundCloud(store, settings, client: mockClient);

      final page = await sc.userTracks(10);
      expect(page.items.first.title, 'User Track 1');
      expect(page.next, isNotNull);

      final topPage = await sc.userTopTracks(10);
      expect(topPage.items.first.title, 'Top Track 1');

      final plPage = await sc.userPlaylists(10);
      expect(plPage.items.first.title, 'User Playlist 1');

      final singleTrack = await sc.track(500);
      expect(singleTrack.title, 'Single Track 500');
    });

    test('HTTP error responses throw ScException with status code', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/tracks/999') {
          return http.Response('Bad Request', 400);
        }
        return http.Response('Not Found', 404);
      });

      final sc = SoundCloud(store, settings, client: mockClient);
      expect(() => sc.track(999), throwsA(isA<ScException>().having((e) => e.status, 'status', 400)));
    });
  });
}

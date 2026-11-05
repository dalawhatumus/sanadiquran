import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../backend/calls.dart';
import '../../backend/config.dart';

enum LinkState { connecting, connected, reconnecting, failed }

/// The live audio between the two phones.
abstract class AudioLink {
  /// The student calls (makes the offer); the teacher answers.
  Future<void> start(String callId, {required bool asStudent});

  ValueListenable<LinkState> get state;

  Future<void> setMuted(bool muted);
  Future<void> setSpeaker(bool on);
  Future<void> close();
}

/// Demo mode: no audio, connected at once.
class FakeAudioLink implements AudioLink {
  final _state = ValueNotifier(LinkState.connecting);

  @override
  ValueListenable<LinkState> get state => _state;

  @override
  Future<void> start(String callId, {required bool asStudent}) async => _state.value = LinkState.connected;

  @override
  Future<void> setMuted(bool muted) async {}

  @override
  Future<void> setSpeaker(bool on) async {}

  @override
  Future<void> close() async {}
}

/// WebRTC audio, with the connection details exchanged through the call
/// document. Uses Google's public STUN server, plus a TURN relay when one is
/// configured (for networks that block direct connections).
class WebRtcAudioLink implements AudioLink {
  WebRtcAudioLink(this.api);

  final CallApi api;
  final _state = ValueNotifier(LinkState.connecting);
  RTCPeerConnection? _pc;
  MediaStream? _mic;
  final _subs = <StreamSubscription<Object?>>[];
  final _seen = <String>{};
  final _pending = <RTCIceCandidate>[];
  bool _remoteSet = false;
  Timer? _dropTimer;

  /// Closed (hung up) while still starting: whatever start() gets after
  /// that is released at once, so the microphone is never left on.
  bool _closed = false;

  @override
  ValueListenable<LinkState> get state => _state;

  static Map<String, dynamic> get _config => {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      if (TurnConfig.isSet)
        {'urls': TurnConfig.urls, 'username': TurnConfig.username, 'credential': TurnConfig.credential},
    ],
    'sdpSemantics': 'unified-plan',
  };

  @override
  Future<void> start(String callId, {required bool asStudent}) async {
    final pc = _pc = await createPeerConnection(_config);
    if (_closed) {
      _pc = null;
      await pc.close();
      return;
    }
    final mic = await navigator.mediaDevices.getUserMedia({
      'audio': {'echoCancellation': true, 'noiseSuppression': true, 'autoGainControl': true},
      'video': false,
    });
    if (_closed) {
      for (final t in mic.getTracks()) {
        await t.stop();
      }
      await mic.dispose();
      return;
    }
    _mic = mic;
    for (final track in mic.getAudioTracks()) {
      await pc.addTrack(track, mic);
    }
    // The loudspeaker (an elderly student often holds the phone away to
    // read), but a Bluetooth headset or hearing aid when one is connected.
    await Helper.setSpeakerphoneOnButPreferBluetooth();

    pc.onIceCandidate = (c) {
      if (c.candidate == null || _closed) return;
      api
          .addIceCandidate(callId, fromStudent: asStudent, candidate: (c.toMap() as Map).cast<String, dynamic>())
          .catchError((Object e) => debugPrint('ICE not sent: $e'));
    };
    pc.onIceConnectionState = (s) {
      if (_closed) return;
      switch (s) {
        case RTCIceConnectionState.RTCIceConnectionStateConnected:
        case RTCIceConnectionState.RTCIceConnectionStateCompleted:
          _dropTimer?.cancel();
          _dropTimer = null;
          _state.value = LinkState.connected;
        case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
          // Often recovers by itself (e.g. moving between Wi-Fi and mobile
          // data); give it time before giving up.
          if (_state.value == LinkState.connected) _state.value = LinkState.reconnecting;
          _dropTimer ??= Timer(const Duration(seconds: 20), () {
            if (!_closed) _state.value = LinkState.failed;
          });
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
          _dropTimer?.cancel();
          _dropTimer = null;
          _state.value = LinkState.failed;
        default:
          break;
      }
    };

    // Routes from the other phone, applied once its description is known.
    _subs.add(
      api.iceCandidates(callId, fromStudent: !asStudent).listen(onError: (Object e) => debugPrint('ICE: $e'), (
        list,
      ) async {
        for (final m in list) {
          final key = '${m['candidate']}';
          if (!_seen.add(key)) continue;
          final c = RTCIceCandidate(
            m['candidate'] as String?,
            m['sdpMid'] as String?,
            (m['sdpMLineIndex'] as num?)?.toInt(),
          );
          if (_remoteSet) {
            await pc.addCandidate(c).catchError((Object e) => debugPrint('Route not added: $e'));
          } else {
            _pending.add(c);
          }
        }
      }),
    );

    Future<void> remote(Map<String, dynamic> d) async {
      if (_remoteSet) return;
      _remoteSet = true;
      await pc.setRemoteDescription(RTCSessionDescription(d['sdp'] as String?, d['type'] as String?));
      for (final c in [..._pending]) {
        await pc.addCandidate(c).catchError((Object e) => debugPrint('Route not added: $e'));
      }
      _pending.clear();
    }

    if (asStudent) {
      final offer = await pc.createOffer({'offerToReceiveAudio': true, 'offerToReceiveVideo': false});
      await pc.setLocalDescription(offer);
      await api.setOffer(callId, {'type': offer.type, 'sdp': offer.sdp});
      _subs.add(
        api.watchCall(callId).listen((c) {
          final a = c?.answer;
          if (a != null && !_closed) remote(a).catchError((Object e) => _fail('Answer not applied: $e'));
        }, onError: (Object e) => debugPrint('Call: $e')),
      );
    } else {
      _subs.add(
        api.watchCall(callId).listen((c) async {
          final o = c?.offer;
          if (o == null || _remoteSet || _closed) return;
          try {
            await remote(o);
            final answer = await pc.createAnswer({'offerToReceiveAudio': true, 'offerToReceiveVideo': false});
            await pc.setLocalDescription(answer);
            await api.setAnswer(callId, {'type': answer.type, 'sdp': answer.sdp});
          } catch (e) {
            _fail('Answer not sent: $e');
          }
        }, onError: (Object e) => debugPrint('Call: $e')),
      );
    }
    // If nothing connects within 40 seconds, the call can't go through.
    _dropTimer?.cancel();
    _dropTimer = Timer(const Duration(seconds: 40), () {
      _dropTimer = null;
      if (_state.value == LinkState.connecting && !_closed) _state.value = LinkState.failed;
    });
  }

  void _fail(String why) {
    debugPrint(why);
    if (!_closed) _state.value = LinkState.failed;
  }

  @override
  Future<void> setMuted(bool muted) async {
    for (final t in _mic?.getAudioTracks() ?? const <MediaStreamTrack>[]) {
      t.enabled = !muted;
    }
  }

  @override
  Future<void> setSpeaker(bool on) =>
      on ? Helper.setSpeakerphoneOnButPreferBluetooth() : Helper.setSpeakerphoneOn(false);

  @override
  Future<void> close() async {
    _closed = true;
    _dropTimer?.cancel();
    _dropTimer = null;
    for (final s in _subs) {
      await s.cancel();
    }
    for (final t in _mic?.getTracks() ?? const <MediaStreamTrack>[]) {
      await t.stop();
    }
    await _mic?.dispose();
    _mic = null;
    await _pc?.close();
    _pc = null;
  }
}

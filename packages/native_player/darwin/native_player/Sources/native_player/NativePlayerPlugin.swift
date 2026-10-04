#if os(iOS)
import Flutter
import UIKit
typealias PlatformImage = UIImage
#else
import FlutterMacOS
import AppKit
typealias PlatformImage = NSImage
#endif
import AVFoundation
import MediaPlayer

/// AVPlayer + Now Playing / remote commands (lock screen, Control Center, AirPods, Touch Bar).
///
/// Crossfade like on Android: the new track starts on a second AVPlayer, both are blended with
/// an equal-power curve and the new player takes over the observers (it becomes [player]).
public class NativePlayerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var player = NativePlayerPlugin.makePlayer()
  /// Old deck during a crossfade (silent towards Dart, stopped at the end).
  private var fading: AVPlayer?
  private var fadeTimer: Timer?
  private var tempoTimer: Timer?
  private var volume: Float = 1
  /// Speed chosen by the user; DJ tempo matching deviates from it only temporarily.
  private var masterRate: Float = 1
  private var sink: FlutterEventSink?
  private var timeObserver: Any?
  private var observations: [NSKeyValueObservation] = []
  private var itemObservation: NSKeyValueObservation?
  private var info: [String: Any] = [:]
  private var artworkTask: URLSessionDataTask?
  private var ended = false

  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(iOS)
    let messenger = registrar.messenger()
    #else
    let messenger = registrar.messenger
    #endif
    let instance = NativePlayerPlugin()
    let methods = FlutterMethodChannel(name: "pounce/player", binaryMessenger: messenger)
    registrar.addMethodCallDelegate(instance, channel: methods)
    FlutterEventChannel(name: "pounce/player/events", binaryMessenger: messenger)
      .setStreamHandler(instance)
    instance.setUp()
  }

  private func setUp() {
    #if os(iOS)
    try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .longFormAudio)
    NotificationCenter.default.addObserver(
      self, selector: #selector(onInterruption(_:)),
      name: AVAudioSession.interruptionNotification, object: nil)
    #endif
    attach(player)

    NotificationCenter.default.addObserver(
      self, selector: #selector(onEnd(_:)),
      name: .AVPlayerItemDidPlayToEndTime, object: nil)

    let cc = MPRemoteCommandCenter.shared()
    cc.playCommand.addTarget { [weak self] _ in self?.send("play"); return .success }
    cc.pauseCommand.addTarget { [weak self] _ in self?.send("pause"); return .success }
    cc.togglePlayPauseCommand.addTarget { [weak self] _ in
      guard let self else { return .commandFailed }
      self.send(self.player.rate > 0 ? "pause" : "play")
      return .success
    }
    cc.nextTrackCommand.addTarget { [weak self] _ in self?.send("next"); return .success }
    cc.previousTrackCommand.addTarget { [weak self] _ in self?.send("previous"); return .success }
    cc.changePlaybackPositionCommand.addTarget { [weak self] e in
      guard let e = e as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
      self?.seek(ms: Int(e.positionTime * 1000))
      return .success
    }
  }

  private static func makePlayer() -> AVPlayer {
    let p = AVPlayer()
    p.automaticallyWaitsToMinimizeStalling = true
    return p
  }

  /// Position/status observers on the player that reports to Dart.
  private func attach(_ p: AVPlayer) {
    timeObserver = p.addPeriodicTimeObserver(
      forInterval: CMTime(seconds: 1, preferredTimescale: 1000), queue: .main
    ) { [weak self] _ in self?.emit() }

    observations = [p.observe(\.timeControlStatus, options: [.new]) { [weak self] _, _ in
      DispatchQueue.main.async { self?.emit(); self?.updateNowPlayingRate() }
    }]
  }

  private func detach(_ p: AVPlayer) {
    if let o = timeObserver { p.removeTimeObserver(o) }
    timeObserver = nil
    observations.forEach { $0.invalidate() }
    observations = []
  }

  // MARK: Channels

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    emit()
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "load":
      guard let a = call.arguments as? [String: Any],
            let s = a["url"] as? String, let url = URL(string: s) else {
        return result(FlutterError(code: "args", message: "url fehlt", details: nil))
      }
      finishFade()
      resetTempo()
      load(url: url, args: a)
    case "crossfade":
      guard let a = call.arguments as? [String: Any],
            let s = a["url"] as? String, let url = URL(string: s) else {
        return result(FlutterError(code: "args", message: "url fehlt", details: nil))
      }
      crossfade(url: url, args: a)
    case "play":
      activateSession()
      if ended { player.seek(to: .zero); ended = false }
      player.play()
    case "pause":
      finishFade()
      player.pause()
    case "seek": seek(ms: (call.arguments as? NSNumber)?.intValue ?? 0)
    case "stop":
      finishFade()
      player.pause()
      player.replaceCurrentItem(with: nil)
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    case "volume":
      volume = (call.arguments as? NSNumber)?.floatValue ?? 1
      if fadeTimer == nil { player.volume = volume }
    case "speed":
      let r = (call.arguments as? NSNumber)?.floatValue ?? 1
      masterRate = r
      tempoTimer?.invalidate()
      tempoTimer = nil
      if #available(iOS 16.0, macOS 13.0, *) {
        player.defaultRate = r
      }
      if player.rate > 0 { player.rate = r }
    default:
      return result(FlutterMethodNotImplemented)
    }
    result(nil)
  }

  // MARK: Playback

  private func load(url: URL, args: [String: Any]) {
    ended = false
    let item = AVPlayerItem(url: url)
    itemObservation = item.observe(\.status, options: [.new]) { [weak self] _, _ in
      DispatchQueue.main.async { self?.emit() }
    }
    player.replaceCurrentItem(with: item)
    let start = (args["startMs"] as? NSNumber)?.intValue ?? 0
    if start > 0 { seek(ms: start) }

    info = [
      MPMediaItemPropertyTitle: args["title"] as? String ?? "",
      MPMediaItemPropertyArtist: args["artist"] as? String ?? "",
      MPMediaItemPropertyPlaybackDuration: Double((args["durationMs"] as? NSNumber)?.intValue ?? 0) / 1000,
      MPNowPlayingInfoPropertyElapsedPlaybackTime: Double(start) / 1000,
      MPNowPlayingInfoPropertyPlaybackRate: 0.0,
    ]
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    loadArtwork(args["artUrl"] as? String)

    if (args["play"] as? Bool) != false {
      activateSession()
      player.play()
    }
  }

  /// Equal-power crossfade into [url]. "tempo" matches the new track's tempo to the old one
  /// (0.9–1.1); afterwards it glides back to the user's speed.
  private func crossfade(url: URL, args: [String: Any]) {
    let seconds = Double((args["durationMs"] as? NSNumber)?.intValue ?? 3000) / 1000
    // Nothing audible to fade out: a plain load is the same.
    guard player.timeControlStatus == .playing, seconds > 0 else {
      finishFade()
      resetTempo()
      return load(url: url, args: args)
    }
    finishFade()
    tempoTimer?.invalidate()
    tempoTimer = nil

    let old = player
    detach(old)
    let next = NativePlayerPlugin.makePlayer()
    next.volume = 0
    player = next
    fading = old
    attach(next)

    let tempo = (args["tempo"] as? NSNumber)?.floatValue ?? 1
    let matched = masterRate * min(max(tempo, 0.9), 1.1)
    if #available(iOS 16.0, macOS 13.0, *) { next.defaultRate = matched }
    load(url: url, args: args)
    next.rate = matched

    // The clock only runs once the new deck actually plays, so a slow start doesn't eat the fade.
    let step = 0.03
    var t = 0.0
    fadeTimer = Timer.scheduledTimer(withTimeInterval: step, repeats: true) { [weak self] timer in
      guard let self else { return timer.invalidate() }
      guard next.timeControlStatus == .playing else { return }
      t += step / seconds
      if t >= 1 {
        self.finishFade()
        if matched != self.masterRate { self.tempoBack(next, from: matched) }
        return
      }
      next.volume = self.volume * Float(sin(t * .pi / 2))
      old.volume = self.volume * Float(cos(t * .pi / 2))
    }
    emit()
  }

  /// Ends a running crossfade at once: the old deck stops, the new one plays at full volume.
  private func finishFade() {
    fadeTimer?.invalidate()
    fadeTimer = nil
    if let f = fading {
      f.pause()
      f.replaceCurrentItem(with: nil)
    }
    fading = nil
    player.volume = volume
  }

  /// After the transition, inaudibly (8 s) bring the tempo back to the user's speed.
  private func tempoBack(_ p: AVPlayer, from: Float) {
    var k: Float = 0
    tempoTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
      guard let self else { return timer.invalidate() }
      k = min(1, k + 1 / 80)
      let r = from + (self.masterRate - from) * k
      if #available(iOS 16.0, macOS 13.0, *) { p.defaultRate = r }
      if p.rate > 0 { p.rate = r }
      if k >= 1 {
        timer.invalidate()
        self.tempoTimer = nil
      }
    }
  }

  /// A new track plays at the user's speed (a running tempo ramp is dropped).
  private func resetTempo() {
    guard tempoTimer != nil else { return }
    tempoTimer?.invalidate()
    tempoTimer = nil
    if #available(iOS 16.0, macOS 13.0, *) { player.defaultRate = masterRate }
  }

  private func seek(ms: Int) {
    let t = CMTime(value: CMTimeValue(ms), timescale: 1000)
    ended = false
    player.seek(to: t, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
      self?.emit()
      self?.updateNowPlayingRate()
    }
  }

  private func activateSession() {
    #if os(iOS)
    try? AVAudioSession.sharedInstance().setActive(true)
    #endif
  }

  private func loadArtwork(_ s: String?) {
    artworkTask?.cancel()
    guard let s, let url = URL(string: s) else { return }
    artworkTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
      guard let data, let img = PlatformImage(data: data) else { return }
      DispatchQueue.main.async {
        guard let self else { return }
        self.info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = self.info
      }
    }
    artworkTask?.resume()
  }

  private func updateNowPlayingRate() {
    info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds.isFinite ? player.currentTime().seconds : 0
    info[MPNowPlayingInfoPropertyPlaybackRate] = Double(player.rate)
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    #if os(macOS)
    MPNowPlayingInfoCenter.default().playbackState = player.rate > 0 ? .playing : .paused
    #endif
  }

  @objc private func onEnd(_ n: Notification) {
    guard (n.object as? AVPlayerItem) === player.currentItem else { return }
    ended = true
    emit()
  }

  #if os(iOS)
  @objc private func onInterruption(_ n: Notification) {
    guard let raw = n.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
          AVAudioSession.InterruptionType(rawValue: raw) == .ended,
          let opt = n.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt,
          AVAudioSession.InterruptionOptions(rawValue: opt).contains(.shouldResume) else { return }
    player.play()
  }
  #endif

  // MARK: Events

  private func send(_ command: String) {
    sink?(["type": "command", "command": command])
  }

  private func emit() {
    guard let sink else { return }
    let item = player.currentItem
    let status: String
    if item == nil { status = "idle" }
    else if item?.status == .failed { status = "error" }
    else if ended { status = "ended" }
    else if player.timeControlStatus == .waitingToPlayAtSpecifiedRate || item?.status == .unknown { status = "loading" }
    else { status = "ready" }

    func ms(_ t: CMTime?) -> Int {
      guard let t, t.isNumeric, t.seconds.isFinite else { return 0 }
      return Int(t.seconds * 1000)
    }
    let buffered = item?.loadedTimeRanges.last.map { CMTimeRangeGetEnd($0.timeRangeValue) }

    sink([
      "type": "state",
      "status": status,
      "playing": player.timeControlStatus == .playing,
      "position": ms(player.currentTime()),
      "duration": ms(item?.duration),
      "buffered": ms(buffered),
      "error": item?.error?.localizedDescription as Any,
    ])
  }
}

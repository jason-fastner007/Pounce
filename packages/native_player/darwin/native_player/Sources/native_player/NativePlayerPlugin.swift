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
public class NativePlayerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private let player = AVPlayer()
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
    player.automaticallyWaitsToMinimizeStalling = true

    timeObserver = player.addPeriodicTimeObserver(
      forInterval: CMTime(seconds: 1, preferredTimescale: 1000), queue: .main
    ) { [weak self] _ in self?.emit() }

    observations.append(player.observe(\.timeControlStatus, options: [.new]) { [weak self] _, _ in
      DispatchQueue.main.async { self?.emit(); self?.updateNowPlayingRate() }
    })

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
      load(url: url, args: a)
    case "play":
      activateSession()
      if ended { player.seek(to: .zero); ended = false }
      player.play()
    case "pause": player.pause()
    case "seek": seek(ms: (call.arguments as? NSNumber)?.intValue ?? 0)
    case "stop":
      player.pause()
      player.replaceCurrentItem(with: nil)
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    case "volume": player.volume = (call.arguments as? NSNumber)?.floatValue ?? 1
    case "speed":
      let r = (call.arguments as? NSNumber)?.floatValue ?? 1
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

{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  config: {
    // By default Flutter only uses the Wasm renderer (Skwasm) in Chromium browsers.
    // Firefox (120+, WasmGC) runs it too: in testing 60 instead of ~50 FPS during
    // playback, on separate render threads with cross-origin isolation (web/_headers).
    // Requirement: no cacheWidth/ResizeImage on the web (Skwasm in Firefox scales wrongly).
    // Safari stays on the JS build (CanvasKit).
    wasmAllowList: { blink: true, gecko: true },
  },
});

// Analysis worker: deckengine (Rust → WebAssembly) off the UI thread.
// Messages: {id, op: 'clip', head, clip, offset, duration, env, fakeprint}
//           {id, op: 'events', head, clip, offset, period, downbeat, bassBody, wantCue}
//           {id, op: 'fakeprint', pcm, rate}
// Reply:    {id, ok: true, values: [...]} or {id, ok: false, error}
'use strict';

let enginePromise = null;

function engine() {
  if (!enginePromise) {
    const url = new URL('deckengine.wasm', self.location).href;
    enginePromise = WebAssembly.instantiateStreaming(fetch(url), {})
      .catch(async () => WebAssembly.instantiate(await (await fetch(url)).arrayBuffer(), {}))
      .then((r) => r.instance.exports);
  }
  return enginePromise;
}

function put(e, view) {
  const bytes = new Uint8Array(view.buffer, view.byteOffset, view.byteLength);
  const p = e.de_alloc(bytes.length);
  new Uint8Array(e.memory.buffer, p, bytes.length).set(bytes);
  return p;
}

// DeTrackAnalysis: 7 × f64, then 16 × 32 bit (key_pitch/key_minor are i32, bass_body_db last).
const STRUCT = 120;
// DeEvents: cue_ms f64, drop_ms f64, drop_strength f32, reserved f32.
const EVENTS = 24;

function readAnalysis(e, p) {
  const dv = new DataView(e.memory.buffer, p, STRUCT);
  const out = [];
  for (let i = 0; i < 7; i++) out.push(dv.getFloat64(i * 8, true));
  for (let i = 0; i < 16; i++) {
    const off = 56 + i * 4;
    out.push(i === 4 || i === 5 ? dv.getInt32(off, true) : dv.getFloat32(off, true));
  }
  return out;
}

async function clip(msg) {
  const e = await engine();
  const head = put(e, msg.head);
  const clipPtr = put(e, msg.clip);
  const env = msg.env && msg.env.length ? put(e, msg.env) : 0;
  const out = e.de_alloc(STRUCT);
  try {
    const rc = e.de_analyze_mp3_clip(
      head, msg.head.byteLength, clipPtr, msg.clip.byteLength, BigInt(Math.round(msg.offset)),
      msg.duration, env, msg.env ? msg.env.length : 0, msg.fakeprint ? 1 : 0, out);
    return rc === 0 ? readAnalysis(e, out) : null;
  } finally {
    e.de_free(head, msg.head.byteLength);
    e.de_free(clipPtr, msg.clip.byteLength);
    if (env) e.de_free(env, msg.env.byteLength);
    e.de_free(out, STRUCT);
  }
}

async function events(msg) {
  const e = await engine();
  if (!e.de_scan_events) return null; // older deckengine.wasm
  const head = put(e, msg.head);
  const clipPtr = put(e, msg.clip);
  const out = e.de_alloc(EVENTS);
  try {
    const rc = e.de_scan_events(
      head, msg.head.byteLength, clipPtr, msg.clip.byteLength, BigInt(Math.round(msg.offset)),
      msg.period, msg.downbeat, msg.bassBody, msg.wantCue ? 1 : 0, out);
    if (rc !== 0) return null;
    const dv = new DataView(e.memory.buffer, out, EVENTS);
    return [dv.getFloat64(0, true), dv.getFloat64(8, true), dv.getFloat32(16, true)];
  } finally {
    e.de_free(head, msg.head.byteLength);
    e.de_free(clipPtr, msg.clip.byteLength);
    e.de_free(out, EVENTS);
  }
}

async function fakeprint(msg) {
  const e = await engine();
  const pcm = put(e, msg.pcm);
  const out = e.de_alloc(4);
  try {
    const rc = e.de_fakeprint(pcm, msg.pcm.length, msg.rate, out);
    const v = new DataView(e.memory.buffer, out, 4).getFloat32(0, true);
    return rc === 0 && v >= 0 ? [v] : null;
  } finally {
    e.de_free(pcm, msg.pcm.byteLength);
    e.de_free(out, 4);
  }
}

self.onmessage = async (ev) => {
  const msg = ev.data;
  try {
    const values =
      msg.op === 'clip' ? await clip(msg) : msg.op === 'events' ? await events(msg) : await fakeprint(msg);
    self.postMessage({ id: msg.id, ok: values !== null, values });
  } catch (err) {
    self.postMessage({ id: msg.id, ok: false, error: String(err) });
  }
};

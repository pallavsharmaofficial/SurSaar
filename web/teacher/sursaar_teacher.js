/*
 * SurSaar teacher runtime for the web build (v2).
 *
 * Owns what the Flutter app cannot do from Dart alone:
 *   - the camera preview (one persistent <video>, mounted through platform views)
 *   - MediaPipe hand tracking, in a Web Worker when possible (never blocks the UI)
 *   - microphone capture (AudioWorklet, raw – no AGC / echo / noise processing)
 *   - metronome click, reference chord sounds and spoken coaching
 *
 * All processing stays in the browser. No audio or video ever leaves the device.
 */
(function () {
  'use strict';

  const VERSION = '2.0.0';
  const MP_VERSION = '1.0.1';
  const MP_BASE = 'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@' + MP_VERSION;
  const MODEL_URL =
    'https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task';
  const WORKER_MAX_FPS = 30;
  const MAIN_THREAD_MAX_FPS = 15;

  const scriptBase = document.currentScript && document.currentScript.src
    ? new URL('.', document.currentScript.src).href
    : new URL('teacher/', document.baseURI).href;

  function isSupported() {
    return !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia && window.isSecureContext);
  }

  function describeMediaError(err, device) {
    const name = err && err.name;
    if (name === 'NotAllowedError' || name === 'SecurityError') {
      return `Access to the ${device} was blocked. Allow it from the icon in the address bar, then try again.`;
    }
    if (name === 'NotFoundError' || name === 'OverconstrainedError') return `No ${device} was found on this device.`;
    if (name === 'NotReadableError' || name === 'AbortError') {
      return `The ${device} is busy in another app or tab. Close it there and try again.`;
    }
    return `Could not start the ${device}: ${(err && err.message) || err}`;
  }

  // ------------------------------------------------------------------ vision

  const vision = {
    status: 'idle', // idle | loading | ready | error
    error: null,
    mode: null, // worker | main
    delegate: null,
    worker: null,
    landmarker: null,
    readyPromise: null,
    statusListeners: [],
    running: false,
    stream: null,
    onFrame: null,
    onError: null,
    loopGen: 0,
    frameHandle: null,
    usingRvfc: false,
    lastStep: 0,
    watchdog: null,
    resumeTimer: null,
    inFlight: false,
    inFlightSince: 0,
    lastSent: 0,
    lastTs: 0,
    sent: 0,
    results: 0,
    detectMsTotal: 0,
    errors: 0,
    resultTimes: [],
    resumes: 0,
  };
  let container = null;
  let video = null;
  let mirror = true;
  let visionModule = null;

  function ensureContainer() {
    if (container) return container;
    container = document.createElement('div');
    container.className = 'sursaar-vision';
    Object.assign(container.style, {
      width: '100%', height: '100%', overflow: 'hidden', background: '#0F172A', position: 'relative',
    });
    video = document.createElement('video');
    video.autoplay = true;
    video.muted = true;
    video.playsInline = true;
    video.setAttribute('playsinline', '');
    video.setAttribute('muted', '');
    Object.assign(video.style, {
      width: '100%', height: '100%', objectFit: 'cover', display: 'block',
      transform: mirror ? 'scaleX(-1)' : 'none',
    });
    // A playing video is paused by the browser when it is moved or detached.
    video.addEventListener('pause', () => { if (vision.running) resumeVideoSoon(); });
    container.appendChild(video);
    return container;
  }

  /** Platform-view factory: a fresh host per view that adopts the shared preview. */
  function createVisionView(viewId) {
    const host = document.createElement('div');
    host.setAttribute('data-sursaar-view', String(viewId));
    Object.assign(host.style, { width: '100%', height: '100%' });
    host.appendChild(ensureContainer());
    if (vision.running) resumeVideoSoon();
    return host;
  }

  function getVisionContainer() {
    return ensureContainer();
  }

  function setMirror(value) {
    mirror = !!value;
    if (video) video.style.transform = mirror ? 'scaleX(-1)' : 'none';
  }

  function resumeVideoSoon() {
    if (vision.resumeTimer) return;
    vision.resumeTimer = setTimeout(function attempt() {
      vision.resumeTimer = null;
      if (!vision.running || !video || !video.srcObject || !video.paused) return;
      vision.resumes++;
      video.play().catch(() => {
        vision.resumeTimer = setTimeout(attempt, 250);
      });
    }, 60);
  }

  function setStatus(status) {
    vision.status = status;
    vision.statusListeners.slice().forEach((fn) => { try { fn(status); } catch (_) { /* ignore */ } });
  }

  function reportError(message) {
    if (vision.onError) {
      try { vision.onError(message); } catch (_) { /* ignore */ }
    }
  }

  function canUseWorker() {
    return typeof Worker !== 'undefined' && typeof createImageBitmap === 'function' && typeof OffscreenCanvas !== 'undefined';
  }

  function initWorker() {
    return new Promise((resolve, reject) => {
      let worker;
      try {
        worker = new Worker(scriptBase + 'hand_worker.js', { type: 'module' });
      } catch (err) {
        reject(err);
        return;
      }
      vision.worker = worker;
      const timer = setTimeout(() => reject(new Error('hand tracking worker timed out')), 90000);
      worker.onmessage = (ev) => {
        const msg = ev.data || {};
        if (msg.type === 'ready') {
          clearTimeout(timer);
          vision.delegate = msg.delegate;
          worker.onmessage = onWorkerMessage;
          resolve();
        } else if (msg.type === 'error') {
          clearTimeout(timer);
          reject(new Error(msg.message));
        }
      };
      worker.onerror = (ev) => {
        clearTimeout(timer);
        reject(new Error((ev && ev.message) || 'hand tracking worker failed'));
      };
      worker.postMessage({ type: 'init', base: MP_BASE, model: MODEL_URL });
    });
  }

  function terminateWorker() {
    if (vision.worker) {
      try { vision.worker.terminate(); } catch (_) { /* ignore */ }
    }
    vision.worker = null;
  }

  async function initMainThread() {
    visionModule = visionModule || (await import(MP_BASE + '/vision_bundle.mjs'));
    const { FilesetResolver, HandLandmarker } = visionModule;
    const fileset = await FilesetResolver.forVisionTasks(MP_BASE + '/wasm');
    const options = (delegate) => ({
      baseOptions: { modelAssetPath: MODEL_URL, delegate },
      runningMode: 'VIDEO',
      numHands: 2,
      minHandDetectionConfidence: 0.5,
      minHandPresenceConfidence: 0.5,
      minTrackingConfidence: 0.5,
    });
    try {
      vision.landmarker = await HandLandmarker.createFromOptions(fileset, options('GPU'));
      vision.delegate = 'GPU';
    } catch (err) {
      vision.landmarker = await HandLandmarker.createFromOptions(fileset, options('CPU'));
      vision.delegate = 'CPU';
    }
  }

  /** Downloads and initialises hand tracking. Safe to call many times. */
  function preloadVision(onStatus) {
    if (typeof onStatus === 'function') vision.statusListeners.push(onStatus);
    if (vision.status === 'ready') {
      if (typeof onStatus === 'function') onStatus('ready');
      return Promise.resolve(true);
    }
    if (vision.readyPromise) return vision.readyPromise;
    setStatus('loading');
    vision.readyPromise = (async () => {
      try {
        if (canUseWorker()) {
          try {
            await initWorker();
            vision.mode = 'worker';
          } catch (err) {
            console.warn('[SurSaar] hand tracking worker unavailable, using the main thread:', (err && err.message) || err);
            terminateWorker();
            await initMainThread();
            vision.mode = 'main';
          }
        } else {
          await initMainThread();
          vision.mode = 'main';
        }
        vision.error = null;
        setStatus('ready');
        if (vision.running) startLoop();
        return true;
      } catch (err) {
        vision.error = String((err && err.message) || err);
        vision.readyPromise = null;
        setStatus('error');
        return false;
      }
    })();
    return vision.readyPromise;
  }

  function visionStatus() {
    return vision.status;
  }

  function packResult(result) {
    const hands = (result && result.landmarks) || [];
    const flat = new Float32Array(hands.length * 63);
    const handed = [];
    const scores = new Float32Array(hands.length);
    for (let i = 0; i < hands.length; i++) {
      const lm = hands[i];
      for (let j = 0; j < 21 && j < lm.length; j++) {
        flat[i * 63 + j * 3] = lm[j].x;
        flat[i * 63 + j * 3 + 1] = lm[j].y;
        flat[i * 63 + j * 3 + 2] = lm[j].z;
      }
      const cat = result.handedness && result.handedness[i] && result.handedness[i][0];
      handed.push(cat ? cat.categoryName : 'Unknown');
      scores[i] = cat ? cat.score : 0;
    }
    return { flat, handed, scores };
  }

  function deliver(flat, handed, scores, width, height, ms) {
    vision.results++;
    vision.detectMsTotal += ms || 0;
    const now = performance.now();
    vision.resultTimes.push(now);
    while (vision.resultTimes.length && now - vision.resultTimes[0] > 1000) vision.resultTimes.shift();
    if (!vision.running || !vision.onFrame) return;
    try {
      vision.onFrame(flat, handed, scores, Date.now(), width, height);
    } catch (err) {
      console.error('[SurSaar] hand frame callback failed', err);
    }
  }

  function onWorkerMessage(ev) {
    const msg = ev.data || {};
    if (msg.type !== 'result') return;
    vision.inFlight = false;
    if (msg.error) {
      vision.errors++;
      if (vision.errors <= 3) console.warn('[SurSaar] hand tracking frame failed:', msg.error);
      return;
    }
    deliver(msg.flat, msg.handed, msg.scores, msg.width, msg.height, msg.ms);
  }

  function nextTs(now) {
    let ts = Math.round(now);
    if (ts <= vision.lastTs) ts = vision.lastTs + 1;
    vision.lastTs = ts;
    return ts;
  }

  function cancelFrameHandle() {
    if (vision.frameHandle == null) return;
    if (vision.usingRvfc && video && typeof video.cancelVideoFrameCallback === 'function') {
      video.cancelVideoFrameCallback(vision.frameHandle);
    } else {
      clearTimeout(vision.frameHandle);
    }
    vision.frameHandle = null;
  }

  function startLoop() {
    const gen = ++vision.loopGen;
    cancelFrameHandle();
    const step = () => {
      if (gen !== vision.loopGen || !vision.running) return;
      vision.frameHandle = null;
      schedule(step);
      processFrame();
    };
    schedule(step);
  }

  function schedule(step) {
    if (video && !video.paused && typeof video.requestVideoFrameCallback === 'function') {
      vision.usingRvfc = true;
      vision.frameHandle = video.requestVideoFrameCallback(step);
    } else {
      vision.usingRvfc = false;
      vision.frameHandle = setTimeout(step, 1000 / WORKER_MAX_FPS);
    }
  }

  function processFrame() {
    const now = performance.now();
    vision.lastStep = now;
    if (document.hidden || vision.status !== 'ready') return;
    if (!video || video.readyState < 2 || !video.videoWidth) return;
    if (vision.mode === 'worker' && vision.worker) {
      if (vision.inFlight || now - vision.lastSent < 1000 / WORKER_MAX_FPS) return;
      vision.inFlight = true;
      vision.inFlightSince = now;
      vision.lastSent = now;
      vision.sent++;
      const ts = nextTs(now);
      createImageBitmap(video).then(
        (bitmap) => {
          if (!vision.worker || !vision.running) {
            bitmap.close();
            vision.inFlight = false;
            return;
          }
          vision.worker.postMessage({ type: 'detect', bitmap, ts }, [bitmap]);
        },
        () => { vision.inFlight = false; },
      );
    } else if (vision.landmarker) {
      if (now - vision.lastSent < 1000 / MAIN_THREAD_MAX_FPS) return;
      vision.lastSent = now;
      vision.sent++;
      const t0 = performance.now();
      try {
        const packed = packResult(vision.landmarker.detectForVideo(video, nextTs(now)));
        deliver(packed.flat, packed.handed, packed.scores, video.videoWidth, video.videoHeight, performance.now() - t0);
      } catch (err) {
        vision.errors++;
        if (vision.errors <= 3) console.warn('[SurSaar] hand tracking frame failed:', (err && err.message) || err);
      }
    }
  }

  function startWatchdog() {
    stopWatchdog();
    vision.watchdog = setInterval(() => {
      if (!vision.running) return;
      if (video && video.srcObject && video.paused) resumeVideoSoon();
      const now = performance.now();
      if (vision.inFlight && now - vision.inFlightSince > 2000) vision.inFlight = false;
      if (vision.status === 'ready' && now - vision.lastStep > 1500) startLoop();
    }, 500);
  }

  function stopWatchdog() {
    if (vision.watchdog) clearInterval(vision.watchdog);
    vision.watchdog = null;
  }

  async function openCamera(frontCamera) {
    const constraints = {
      video: {
        facingMode: frontCamera ? 'user' : 'environment',
        width: { ideal: 1280 },
        height: { ideal: 720 },
        frameRate: { ideal: 30 },
      },
      audio: false,
    };
    try {
      return await navigator.mediaDevices.getUserMedia(constraints);
    } catch (err) {
      if (err && err.name === 'OverconstrainedError') {
        return navigator.mediaDevices.getUserMedia({ video: true, audio: false });
      }
      throw err;
    }
  }

  /**
   * Starts the camera preview immediately; hand tracking joins as soon as the
   * model is ready. Calling it again while running only updates the callbacks.
   */
  async function startVision(frontCamera, onFrame, onError) {
    vision.onFrame = onFrame;
    vision.onError = onError;
    ensureContainer();
    const live = vision.stream && vision.stream.getVideoTracks().some((t) => t.readyState === 'live');
    if (vision.running && live) {
      resumeVideoSoon();
      return true;
    }
    if (!isSupported()) {
      const message = 'The camera needs a secure (https) page in a browser that supports it.';
      reportError(message);
      throw new Error(message);
    }
    let stream;
    try {
      stream = await openCamera(frontCamera);
    } catch (err) {
      const message = describeMediaError(err, 'camera');
      reportError(message);
      throw new Error(message);
    }
    vision.stream = stream;
    stream.getVideoTracks().forEach((track) => {
      track.onended = () => {
        if (!vision.running) return;
        reportError('The camera stopped. Turn it back on to keep the finger guide.');
        stopVision();
      };
    });
    video.srcObject = stream;
    vision.running = true;
    try {
      await video.play();
    } catch (_) {
      resumeVideoSoon();
    }
    startWatchdog();
    preloadVision().then((ok) => {
      if (ok && vision.running) startLoop();
      if (!ok) reportError('Hand tracking could not load (' + vision.error + '). Chord listening still works.');
    });
    return true;
  }

  function stopVision() {
    vision.running = false;
    vision.loopGen++;
    cancelFrameHandle();
    stopWatchdog();
    if (vision.resumeTimer) clearTimeout(vision.resumeTimer);
    vision.resumeTimer = null;
    if (vision.stream) {
      vision.stream.getTracks().forEach((t) => { t.onended = null; t.stop(); });
      vision.stream = null;
    }
    if (video) {
      try { video.pause(); } catch (_) { /* ignore */ }
      video.srcObject = null;
    }
    vision.inFlight = false;
  }

  document.addEventListener('visibilitychange', () => {
    if (!document.hidden && vision.running) resumeVideoSoon();
  });

  // ------------------------------------------------------------------- audio

  const WORKLET_SOURCE = [
    'class SurSaarCapture extends AudioWorkletProcessor {',
    '  constructor() { super(); this._buf = new Float32Array(2048); this._n = 0; }',
    '  process(inputs) {',
    '    const ch = inputs[0] && inputs[0][0];',
    '    if (!ch) return true;',
    '    for (let i = 0; i < ch.length; i++) {',
    '      this._buf[this._n++] = ch[i];',
    '      if (this._n === this._buf.length) { this.port.postMessage(this._buf.slice(0)); this._n = 0; }',
    '    }',
    '    return true;',
    '  }',
    '}',
    "try { registerProcessor('sursaar-capture', SurSaarCapture); } catch (e) {}",
  ].join('\n');

  const audio = {
    ctx: null,
    stream: null,
    source: null,
    node: null,
    processor: null,
    sink: null,
    workletLoaded: false,
    running: false,
    onChunk: null,
    onError: null,
    chunks: 0,
  };

  function ensureAudioContext() {
    if (!audio.ctx) {
      const Ctx = window.AudioContext || window.webkitAudioContext;
      audio.ctx = new Ctx({ latencyHint: 'interactive' });
    }
    if (audio.ctx.state === 'suspended') audio.ctx.resume().catch(() => {});
    return audio.ctx;
  }

  async function startAudio(onChunk, onError) {
    audio.onChunk = onChunk;
    audio.onError = onError;
    const live = audio.stream && audio.stream.getAudioTracks().some((t) => t.readyState === 'live');
    if (audio.running && live) return true;
    try {
      if (!isSupported()) throw new Error('The microphone needs a secure (https) page.');
      audio.stream = await navigator.mediaDevices.getUserMedia({
        audio: { echoCancellation: false, noiseSuppression: false, autoGainControl: false, channelCount: 1 },
        video: false,
      });
      const ctx = ensureAudioContext();
      if (ctx.state === 'suspended') await ctx.resume();
      audio.source = ctx.createMediaStreamSource(audio.stream);
      const rate = ctx.sampleRate;
      const handle = (data) => {
        audio.chunks++;
        if (audio.running && audio.onChunk) audio.onChunk(data, rate, Date.now());
      };
      audio.sink = ctx.createGain();
      audio.sink.gain.value = 0;
      audio.sink.connect(ctx.destination);
      if (ctx.audioWorklet && typeof AudioWorkletNode !== 'undefined') {
        if (!audio.workletLoaded) {
          const url = URL.createObjectURL(new Blob([WORKLET_SOURCE], { type: 'application/javascript' }));
          await ctx.audioWorklet.addModule(url);
          URL.revokeObjectURL(url);
          audio.workletLoaded = true;
        }
        audio.node = new AudioWorkletNode(ctx, 'sursaar-capture');
        audio.node.port.onmessage = (ev) => handle(ev.data);
        audio.source.connect(audio.node);
        audio.node.connect(audio.sink);
      } else {
        audio.processor = ctx.createScriptProcessor(2048, 1, 1);
        audio.processor.onaudioprocess = (ev) => handle(new Float32Array(ev.inputBuffer.getChannelData(0)));
        audio.source.connect(audio.processor);
        audio.processor.connect(audio.sink);
      }
      audio.stream.getAudioTracks().forEach((track) => {
        track.onended = () => {
          if (!audio.running) return;
          try { audio.onError && audio.onError('The microphone stopped. Turn it back on to keep listening.'); } catch (_) { /* ignore */ }
          stopAudio();
        };
      });
      audio.running = true;
      return true;
    } catch (err) {
      const message = err && err.name ? describeMediaError(err, 'microphone') : String((err && err.message) || err);
      try { onError && onError(message); } catch (_) { /* ignore */ }
      stopAudio();
      return false;
    }
  }

  function stopAudio() {
    audio.running = false;
    try { if (audio.node) { audio.node.port.onmessage = null; audio.node.disconnect(); } } catch (_) { /* ignore */ }
    try { if (audio.processor) { audio.processor.onaudioprocess = null; audio.processor.disconnect(); } } catch (_) { /* ignore */ }
    try { if (audio.source) audio.source.disconnect(); } catch (_) { /* ignore */ }
    try { if (audio.sink) audio.sink.disconnect(); } catch (_) { /* ignore */ }
    audio.node = null;
    audio.processor = null;
    audio.source = null;
    audio.sink = null;
    if (audio.stream) {
      audio.stream.getTracks().forEach((t) => { t.onended = null; t.stop(); });
      audio.stream = null;
    }
  }

  // ------------------------------------------------------------------- sound

  function click(accent) {
    try {
      const ctx = ensureAudioContext();
      const t = ctx.currentTime;
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'square';
      osc.frequency.value = accent ? 1760 : 1175;
      gain.gain.setValueAtTime(0.0001, t);
      gain.gain.exponentialRampToValueAtTime(accent ? 0.35 : 0.22, t + 0.002);
      gain.gain.exponentialRampToValueAtTime(0.0001, t + 0.055);
      osc.connect(gain).connect(ctx.destination);
      osc.start(t);
      osc.stop(t + 0.06);
    } catch (_) { /* ignore */ }
  }

  // Karplus-Strong plucked string.
  function pluck(ctx, midi, when, seconds, level) {
    const freq = 440 * Math.pow(2, (midi - 69) / 12);
    const rate = ctx.sampleRate;
    const length = Math.floor(rate * seconds);
    const buffer = ctx.createBuffer(1, length, rate);
    const data = buffer.getChannelData(0);
    const period = Math.max(2, Math.round(rate / freq));
    const ring = new Float32Array(period);
    for (let i = 0; i < period; i++) ring[i] = Math.random() * 2 - 1;
    const damping = 0.4985 + Math.min(0.0012, freq / 400000);
    let idx = 0;
    for (let i = 0; i < length; i++) {
      const next = (idx + 1) % period;
      const value = ring[idx];
      ring[idx] = (value + ring[next]) * damping;
      data[i] = value;
      idx = next;
    }
    const src = ctx.createBufferSource();
    src.buffer = buffer;
    const gain = ctx.createGain();
    gain.gain.setValueAtTime(level, when);
    gain.gain.exponentialRampToValueAtTime(0.0008, when + seconds);
    src.connect(gain).connect(ctx.destination);
    src.start(when);
  }

  /** Strums MIDI notes (low to high). Returns the sound length in ms. */
  function playChord(notes, down) {
    try {
      const ctx = ensureAudioContext();
      const list = Array.from(notes || []);
      if (!down) list.reverse();
      const start = ctx.currentTime + 0.03;
      list.forEach((midi, i) => pluck(ctx, midi, start + i * 0.035, 2.4, 0.22));
      return 2400 + list.length * 35;
    } catch (_) {
      return 0;
    }
  }

  function playNote(midi) {
    try {
      const ctx = ensureAudioContext();
      pluck(ctx, midi, ctx.currentTime + 0.02, 2.5, 0.35);
      return 2500;
    } catch (_) {
      return 0;
    }
  }

  // ------------------------------------------------------------------ speech

  function speechSupported() {
    return typeof window.speechSynthesis !== 'undefined' && typeof window.SpeechSynthesisUtterance !== 'undefined';
  }

  function speak(text, lang, rate) {
    if (!speechSupported() || !text) return;
    try {
      const utterance = new SpeechSynthesisUtterance(String(text));
      utterance.lang = lang || 'en-US';
      utterance.rate = rate || 1;
      const prefix = utterance.lang.slice(0, 2).toLowerCase();
      const voice = window.speechSynthesis.getVoices().find((v) => (v.lang || '').toLowerCase().startsWith(prefix));
      if (voice) utterance.voice = voice;
      window.speechSynthesis.cancel();
      window.speechSynthesis.speak(utterance);
    } catch (_) { /* ignore */ }
  }

  function cancelSpeech() {
    try { if (speechSupported()) window.speechSynthesis.cancel(); } catch (_) { /* ignore */ }
  }

  // ------------------------------------------------------------------- debug

  function stats() {
    return {
      version: VERSION,
      visionStatus: vision.status,
      visionError: vision.error,
      mode: vision.mode,
      delegate: vision.delegate,
      running: vision.running,
      videoPaused: video ? video.paused : null,
      videoConnected: video ? video.isConnected : null,
      loopGen: vision.loopGen,
      sent: vision.sent,
      results: vision.results,
      detectFps: vision.resultTimes.length,
      avgDetectMs: vision.results ? Math.round((vision.detectMsTotal / vision.results) * 10) / 10 : 0,
      resumes: vision.resumes,
      audioRunning: audio.running,
      audioChunks: audio.chunks,
      workletLoaded: audio.workletLoaded,
    };
  }

  window.SurSaarTeacher = {
    version: VERSION,
    isSupported,
    preloadVision,
    visionStatus,
    createVisionView,
    getVisionContainer,
    setMirror,
    startVision,
    stopVision,
    startAudio,
    stopAudio,
    click,
    playChord,
    playNote,
    speechSupported,
    speak,
    cancelSpeech,
    stats,
  };
})();

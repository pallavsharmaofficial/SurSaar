/*
 * SurSaar teacher runtime for the web build.
 *
 * Owns everything the Flutter app cannot do from Dart alone:
 *   - the camera <video> element (mounted through HtmlElementView)
 *   - MediaPipe Hand Landmarker (loaded on demand from jsDelivr)
 *   - Web Audio microphone capture (AudioWorklet, raw – no AGC / echo /
 *     noise processing so the guitar reaches the chord detector untouched)
 *   - the metronome click
 *
 * All processing stays in the browser. No audio or video ever leaves the
 * device.
 */
(function () {
  'use strict';

  const MP_VERSION = '1.0.1';
  const MP_BASE = 'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@' + MP_VERSION;
  const MODEL_URL =
    'https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task';

  let visionModule = null;
  let landmarker = null;
  let landmarkerPromise = null;
  let container = null;
  let video = null;
  let stream = null;
  let running = false;
  let rafId = null;
  let lastTs = -1;
  let mirror = true;

  let audioCtx = null;
  let audioStream = null;
  let audioSource = null;
  let workletNode = null;
  let processorNode = null;
  let silentGain = null;

  function isSupported() {
    return !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia && window.isSecureContext);
  }

  function getVisionContainer() {
    if (container) return container;
    container = document.createElement('div');
    container.id = 'sursaar-vision';
    Object.assign(container.style, {
      width: '100%',
      height: '100%',
      overflow: 'hidden',
      background: '#000',
      position: 'relative',
    });
    video = document.createElement('video');
    video.autoplay = true;
    video.playsInline = true;
    video.muted = true;
    video.setAttribute('playsinline', '');
    Object.assign(video.style, {
      width: '100%',
      height: '100%',
      objectFit: 'cover',
      transform: mirror ? 'scaleX(-1)' : 'none',
    });
    container.appendChild(video);
    return container;
  }

  function setMirror(value) {
    mirror = !!value;
    if (video) video.style.transform = mirror ? 'scaleX(-1)' : 'none';
  }

  function ensureLandmarker() {
    if (landmarker) return Promise.resolve(landmarker);
    if (landmarkerPromise) return landmarkerPromise;
    landmarkerPromise = (async () => {
      visionModule = visionModule || (await import(MP_BASE + '/vision_bundle.mjs'));
      const { FilesetResolver, HandLandmarker } = visionModule;
      const fileset = await FilesetResolver.forVisionTasks(MP_BASE + '/wasm');
      const options = (delegate) => ({
        baseOptions: { modelAssetPath: MODEL_URL, delegate: delegate },
        runningMode: 'VIDEO',
        numHands: 2,
        minHandDetectionConfidence: 0.5,
        minHandPresenceConfidence: 0.5,
        minTrackingConfidence: 0.5,
      });
      try {
        landmarker = await HandLandmarker.createFromOptions(fileset, options('GPU'));
      } catch (err) {
        console.warn('[SurSaar] GPU delegate unavailable, falling back to CPU', err);
        landmarker = await HandLandmarker.createFromOptions(fileset, options('CPU'));
      }
      return landmarker;
    })();
    landmarkerPromise.catch(() => { landmarkerPromise = null; });
    return landmarkerPromise;
  }

  async function startVision(frontCamera, onFrame, onError) {
    try {
      if (!isSupported()) throw new Error('Camera requires a secure (https) context and getUserMedia support.');
      getVisionContainer();
      stream = await navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: frontCamera ? 'user' : 'environment',
          width: { ideal: 1280 },
          height: { ideal: 720 },
        },
        audio: false,
      });
      video.srcObject = stream;
      await video.play();
      await ensureLandmarker();
      running = true;
      loop(onFrame, onError);
      return true;
    } catch (err) {
      const message = String((err && err.message) || err);
      try { onError(message); } catch (_) { /* ignore */ }
      throw err;
    }
  }

  function loop(onFrame, onError) {
    const step = () => {
      if (!running) return;
      try {
        if (video && video.readyState >= 2 && video.videoWidth > 0 && landmarker) {
          const now = performance.now();
          if (now > lastTs) {
            lastTs = now;
            const result = landmarker.detectForVideo(video, now);
            const hands = result.landmarks || [];
            const flat = new Float32Array(hands.length * 63);
            const handed = [];
            const scores = new Float32Array(hands.length);
            for (let i = 0; i < hands.length; i++) {
              const lm = hands[i];
              for (let j = 0; j < 21; j++) {
                const p = lm[j];
                flat[i * 63 + j * 3] = p.x;
                flat[i * 63 + j * 3 + 1] = p.y;
                flat[i * 63 + j * 3 + 2] = p.z;
              }
              const cat = result.handedness && result.handedness[i] && result.handedness[i][0];
              handed.push(cat ? cat.categoryName : 'Unknown');
              scores[i] = cat ? cat.score : 0;
            }
            onFrame(flat, handed, scores, Date.now(), video.videoWidth, video.videoHeight);
          }
        }
      } catch (err) {
        try { onError(String((err && err.message) || err)); } catch (_) { /* ignore */ }
      }
      if (!running) return;
      if (video && typeof video.requestVideoFrameCallback === 'function') {
        video.requestVideoFrameCallback(step);
      } else {
        rafId = requestAnimationFrame(step);
      }
    };
    step();
  }

  function stopVision() {
    running = false;
    if (rafId) cancelAnimationFrame(rafId);
    rafId = null;
    if (stream) {
      stream.getTracks().forEach((t) => t.stop());
      stream = null;
    }
    if (video) video.srcObject = null;
  }

  // ---------------------------------------------------------------- audio

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
    "registerProcessor('sursaar-capture', SurSaarCapture);",
  ].join('\n');

  function ensureAudioContext() {
    if (!audioCtx) {
      const Ctx = window.AudioContext || window.webkitAudioContext;
      audioCtx = new Ctx({ latencyHint: 'interactive' });
    }
    if (audioCtx.state === 'suspended') audioCtx.resume();
    return audioCtx;
  }

  async function startAudio(onChunk, onError) {
    try {
      if (!isSupported()) throw new Error('Microphone requires a secure (https) context.');
      audioStream = await navigator.mediaDevices.getUserMedia({
        audio: {
          echoCancellation: false,
          noiseSuppression: false,
          autoGainControl: false,
          channelCount: 1,
        },
        video: false,
      });
      const ctx = ensureAudioContext();
      if (ctx.state === 'suspended') await ctx.resume();
      audioSource = ctx.createMediaStreamSource(audioStream);
      const rate = ctx.sampleRate;
      if (ctx.audioWorklet) {
        const url = URL.createObjectURL(new Blob([WORKLET_SOURCE], { type: 'application/javascript' }));
        await ctx.audioWorklet.addModule(url);
        workletNode = new AudioWorkletNode(ctx, 'sursaar-capture');
        workletNode.port.onmessage = (ev) => onChunk(ev.data, rate, Date.now());
        silentGain = ctx.createGain();
        silentGain.gain.value = 0;
        audioSource.connect(workletNode);
        workletNode.connect(silentGain).connect(ctx.destination);
      } else {
        processorNode = ctx.createScriptProcessor(2048, 1, 1);
        processorNode.onaudioprocess = (ev) => onChunk(new Float32Array(ev.inputBuffer.getChannelData(0)), rate, Date.now());
        silentGain = ctx.createGain();
        silentGain.gain.value = 0;
        audioSource.connect(processorNode);
        processorNode.connect(silentGain).connect(ctx.destination);
      }
      return true;
    } catch (err) {
      try { onError(String((err && err.message) || err)); } catch (_) { /* ignore */ }
      return false;
    }
  }

  function stopAudio() {
    try { if (workletNode) { workletNode.port.onmessage = null; workletNode.disconnect(); } } catch (_) { /* ignore */ }
    try { if (processorNode) { processorNode.onaudioprocess = null; processorNode.disconnect(); } } catch (_) { /* ignore */ }
    try { if (audioSource) audioSource.disconnect(); } catch (_) { /* ignore */ }
    try { if (silentGain) silentGain.disconnect(); } catch (_) { /* ignore */ }
    workletNode = null;
    processorNode = null;
    audioSource = null;
    silentGain = null;
    if (audioStream) {
      audioStream.getTracks().forEach((t) => t.stop());
      audioStream = null;
    }
  }

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

  window.SurSaarTeacher = {
    version: '1.0.0',
    isSupported: isSupported,
    getVisionContainer: getVisionContainer,
    setMirror: setMirror,
    startVision: startVision,
    stopVision: stopVision,
    startAudio: startAudio,
    stopAudio: stopAudio,
    click: click,
  };
})();

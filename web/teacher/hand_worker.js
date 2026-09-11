/*
 * SurSaar hand-tracking worker.
 *
 * Runs the MediaPipe Hand Landmarker off the main thread so model loading,
 * GPU shader compilation and per-frame inference never freeze the app.
 * The page sends ImageBitmaps; the worker answers with flat landmark arrays.
 */
let landmarker = null;
let lastTs = 0;

function pack(result) {
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

function nextTs(ts) {
  let value = Math.round(ts);
  if (value <= lastTs) value = lastTs + 1;
  lastTs = value;
  return value;
}

async function init(base, model) {
  const vision = await import(base + '/vision_bundle.mjs');
  const fileset = await vision.FilesetResolver.forVisionTasks(base + '/wasm', true);
  const options = (delegate) => ({
    baseOptions: { modelAssetPath: model, delegate },
    runningMode: 'VIDEO',
    numHands: 2,
    minHandDetectionConfidence: 0.5,
    minHandPresenceConfidence: 0.5,
    minTrackingConfidence: 0.5,
  });
  try {
    landmarker = await vision.HandLandmarker.createFromOptions(fileset, options('GPU'));
    return 'GPU';
  } catch (err) {
    landmarker = await vision.HandLandmarker.createFromOptions(fileset, options('CPU'));
    return 'CPU';
  }
}

self.onmessage = async (event) => {
  const msg = event.data || {};
  if (msg.type === 'init') {
    try {
      const delegate = await init(msg.base, msg.model);
      // Warm up once so the first real frame is not slow.
      try {
        const canvas = new OffscreenCanvas(64, 64);
        canvas.getContext('2d').fillRect(0, 0, 64, 64);
        const warm = canvas.transferToImageBitmap();
        landmarker.detectForVideo(warm, nextTs(performance.now()));
        warm.close();
      } catch (_) { /* warm-up is best effort */ }
      self.postMessage({ type: 'ready', delegate });
    } catch (err) {
      self.postMessage({ type: 'error', message: String((err && err.message) || err) });
    }
    return;
  }
  if (msg.type === 'detect') {
    const bitmap = msg.bitmap;
    try {
      if (!landmarker) throw new Error('hand tracking is not ready');
      const t0 = performance.now();
      const result = landmarker.detectForVideo(bitmap, nextTs(msg.ts));
      const ms = performance.now() - t0;
      const packed = pack(result);
      self.postMessage(
        { type: 'result', flat: packed.flat, handed: packed.handed, scores: packed.scores, width: bitmap.width, height: bitmap.height, ms },
        [packed.flat.buffer, packed.scores.buffer],
      );
    } catch (err) {
      self.postMessage({ type: 'result', error: String((err && err.message) || err) });
    } finally {
      try { bitmap.close(); } catch (_) { /* already closed */ }
    }
  }
};

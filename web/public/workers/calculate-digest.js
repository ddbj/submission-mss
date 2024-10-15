/* global importScripts, hashwasm */

// Same as `import`. To be compatible with Firefox: https://bugzilla.mozilla.org/show_bug.cgi?id=1247687
importScripts('https://cdn.jsdelivr.net/npm/hash-wasm@4.9.0/dist/md5.umd.min.js');

const { createMD5 } = hashwasm;

addEventListener('message', async ({ data: { file } }) => {
  try {
    const digest = await calculateDigest(file);

    postMessage([null, digest]);
  } catch (err) {
    console.error(err);

    postMessage([err.message, null]);
  }
});

async function calculateDigest(file) {
  const md5 = await createMD5();
  md5.init();

  const reader = file.stream().getReader();

  let done, chunk;

  while ((({ done, value: chunk } = await reader.read()), !done)) {
    md5.update(chunk);
  }

  return btoa(String.fromCharCode(...md5.digest('binary')));
}

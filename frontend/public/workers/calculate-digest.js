import { createMD5 } from 'https://cdn.jsdelivr.net/npm/hash-wasm@4.9.0/dist/index.esm.min.js';

addEventListener('message', async ({data: {file}}) => {
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

  while (({done, value: chunk} = await reader.read()), !done) {
    md5.update(chunk);
  }

  return btoa(String.fromCharCode(...md5.digest('binary')));
}

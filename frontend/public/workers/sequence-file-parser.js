addEventListener('message', async (e) => {
  const [id, file] = e.data;
  const reader     = file.stream().getReader();

  let done, bytes;
  let entriesCount = 0;
  let isBOL        = true;

  while (({done, value: bytes} = await reader.read()), !done) {
    for (const byte of bytes) {
      if (isBOL && byte === gt) {
        entriesCount++;
        isBOL = false;
      } else if (byte === lf || byte === cr) {
        isBOL = true;
      } else {
        isBOL = false;
      }
    }
  }

  postMessage([null, [id, {entriesCount}]]);
});

const lf = '\n'.codePointAt(0);
const cr = '\r'.codePointAt(0);
const gt = '>'.codePointAt(0);

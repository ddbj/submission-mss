addEventListener('message', async ({data: {file}}) => {
  const reader = file.stream().getReader();

  let done, chunk;
  let entriesCount = 0;
  let isBOL        = true;

  while (({done, value: chunk} = await reader.read()), !done) {
    for (const byte of chunk) {
      if (isBOL && byte === gt) {
        entriesCount++;
        isBOL = false;
      } else {
        isBOL = byte === lf || byte === cr;
      }
    }
  }

  postMessage({entriesCount});
});

const lf = '\n'.codePointAt(0);
const cr = '\r'.codePointAt(0);
const gt = '>'.codePointAt(0);

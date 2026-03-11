addEventListener('message', async ({ data: { file } }) => {
  try {
    const [errors, payload] = await parse(file);

    postMessage([errors.length ? errors : null, payload]);
  } catch (err) {
    console.error(err);

    postMessage([err.message, null]);
  }
});

async function parse(file) {
  const reader = file.stream().getReader();

  let done, chunk;
  let entriesCount = 0;
  let isBOL = true;

  while ((({ done, value: chunk } = await reader.read()), !done)) {
    for (const byte of chunk) {
      if (isBOL && byte === gt) {
        entriesCount++;
        isBOL = false;
      } else {
        isBOL = byte === lf || byte === cr;
      }
    }
  }

  if (!entriesCount) {
    return [[{ severity: 'error', id: 'sequence-file-parser.no-entries' }], null];
  }

  return [[], { entriesCount }];
}

const lf = '\n'.codePointAt(0);
const cr = '\r'.codePointAt(0);
const gt = '>'.codePointAt(0);

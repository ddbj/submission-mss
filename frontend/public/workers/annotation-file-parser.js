addEventListener('message', async (e) => {
  const [id, file] = e.data;
  const reader     = file.stream().getReader();

  const payload = {
    holdDate:    null,
    fullName:    null,
    email:       null,
    affiliation: null
  };

  let inCommon;

  for await (const line of makeLineIterator(reader)) {
    if (Object.values(payload).every(Boolean)) { break; }

    const [entry, _feature, _location, qualifier, value] = line.replace(/\r\n|\n|\r$/, '').split('\t');

    if (inCommon && entry) { break; }

    if (entry) {
      inCommon = entry === 'COMMON';
    }

    if (!inCommon) { continue; }

    switch (qualifier) {
      case 'hold_date': {
        const m = value.match(/^(\d{4})(\d{2})(\d{2})$/);

        if (!m) { throw new Error(`invalid hold_date: ${value}`); }

        payload.holdDate = m.slice(1).join('-');
        break;
      }
      case 'contact':
        payload.fullName = value;
        break;
      case 'email':
        payload.email = value;
        break;
      case 'institute':
        payload.affiliation = value;
        break;
      default:
        // do nothing
    }
  }

  postMessage([null, [id, payload]]);
});

async function* makeLineIterator(reader) {
  const decoder = new TextDecoder();

  let done, chunk;
  let pending = '';

  while (({done, value: chunk} = await reader.read()), !done) {
    let buffer = pending + decoder.decode(chunk, {stream: true});

    for (;;) {
      let line = null;

      buffer = buffer.replace(/[^\n\r]*(?:\r\n|\n|\r)/, (matched) => {
        line = matched;

        return '';
      });

      if (line) {
        yield line;
      } else {
        break;
      }
    }

    pending = buffer;
  }

  if (pending !== '') {
    yield pending;
  }
}

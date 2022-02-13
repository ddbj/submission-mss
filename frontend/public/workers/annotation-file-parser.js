addEventListener('message', async ({data: {file}}) => {
  try {
    const payload = await parse(file);

    postMessage([null, payload]);
  } catch (err) {
    console.error(err);

    postMessage([err.message, null]);
  }
});

async function parse(file) {
  const reader = file.stream().getReader();

  const payload = {
    fullName:    null,
    email:       null,
    affiliation: null,
    holdDate:    null
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
      case 'contact':
        payload.fullName = value;
        break;
      case 'email':
        payload.email = value;
        break;
      case 'institute':
        payload.affiliation = value;
        break;
      case 'hold_date': {
        const m = value.match(/^(\d{4})(\d{2})(\d{2})$/);

        if (!m) { throw new Error(`hold_date must be an 8-digit number (YYYYMMDD), but: ${value}`); }

        payload.holdDate = m.slice(1).join('-');
        break;
      }
      default:
        // do nothing
    }
  }

  const {fullName, email, affiliation} = payload;

  if ((fullName && email && affiliation) || (!fullName && !email && !affiliation)) {
    return payload;
  } else {
    throw new Error('Contact person information (contact, email, institute) must be included or not included at all.');
  }
}

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

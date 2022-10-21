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

  const contactPerson = new ContactPerson();
  let holdDate        = null;

  let inCommon;

  for await (const line of makeLineIterator(reader)) {
    if (contactPerson.isFulfilled && holdDate) { break; }

    const [entry, _feature, _location, qualifier, value] = line.replace(/\r\n|\n|\r$/, '').split('\t');

    if (inCommon && entry) { break; }

    if (entry) {
      inCommon = entry === 'COMMON';
    }

    if (!inCommon) { continue; }

    switch (qualifier) {
      case 'contact':
        contactPerson.fullName = value;
        break;
      case 'email':
        contactPerson.email = value;
        break;
      case 'institute':
        contactPerson.affiliation = value;
        break;
      case 'hold_date': {
        const m = value.match(/^(\d{4})(\d{2})(\d{2})$/);

        if (!m) { throw new Error(JSON.stringify({id: 'annotation-file-parser.invalid-hold-date', value})); }

        holdDate = m.slice(1).join('-');
        break;
      }
      default:
        // do nothing
    }
  }

  return {
    contactPerson: contactPerson.toPayload(),
    holdDate
  };
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

class ContactPerson {
  get isFulfilled() {
    return this.fullName && this.email && this.affiliation;
  }

  get isBlank() {
    return !this.fullName && !this.email && !this.affiliation;
  }

  toPayload() {
    if (this.isFulfilled) {
      return this;
    } else if (this.isBlank) {
      return null;
    } else {
      throw new Error(JSON.stringify({id: 'annotation-file-parser.invalid-contact-person'}));
    }
  }
}

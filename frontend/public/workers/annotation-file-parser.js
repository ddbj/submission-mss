addEventListener('message', async (e) => {
  const [id, file] = e.data;
  const reader     = file.stream().pipeThrough(new TextDecoderStream()).pipeThrough(new LineStream()).getReader();

  const payload = {
    holdDate:    null,
    fullName:    null,
    email:       null,
    affiliation: null
  };

  let done, line, inCommon;

  while (({done, value: line} = await reader.read()), !done && !Object.values(payload).every(Boolean)) {
    const [entry, _feature, _location, qualifier, value] = line.replace(/\r\n|\n|\r$/, '').split('\t');

    if (entry && inCommon) { break; }

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

class LineStream extends TransformStream {
  constructor() {
    super({
      start() {
        this.pending = '';
      },

      transform(chunk, controller) {
        if (!chunk) { return; }

        const buffer = this.pending + chunk;

        this.pending = buffer.replaceAll(/[^\n\r]*(?:\r\n|\n|\r)/g, (line) => {
          controller.enqueue(line);

          return '';
        });
      },

      flush(controller) {
        if (this.pending === '') { return; }

        controller.enqueue(this.pending);
      }
    });
  }
}

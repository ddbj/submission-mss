addEventListener('message', async (e) => {
  const [id, file] = e.data;
  const reader       = file.stream().pipeThrough(new TextDecoderStream()).pipeThrough(new LineStream()).getReader();

  let done, line;
  let fullName, email, affiliation;

  while (({done, value: line} = await reader.read()), !done && !(fullName && email && affiliation)) {
    if (!fullName) {
      fullName = line.match(/\tcontact\t([^\t\n\r]+)(?:\r\n|\n|\r)?$/)?.[1];
    }

    if (!email) {
      email = line.match(/\temail\t([^\t\n\r]+)(?:\r\n|\n|\r)?$/)?.[1];
    }

    if (!affiliation) {
      affiliation = line.match(/\tinstitute\t([^\t\n\r]+)(?:\r\n|\n|\r)?$/)?.[1];
    }
  }

  postMessage([null, [id, {fullName, email, affiliation}]]);
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

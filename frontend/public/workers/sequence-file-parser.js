addEventListener('message', async (e) => {
  const [id, file] = e.data;
  const reader     = file.stream().pipeThrough(new TextDecoderStream()).pipeThrough(new LineStream()).getReader();

  let done, value;
  let entriesCount = 0;

  while (({done, value} = await reader.read()), !done) {
    if (value.startsWith('>')) {
      entriesCount++;
    }
  }

  postMessage([null, [id, {entriesCount}]]);
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

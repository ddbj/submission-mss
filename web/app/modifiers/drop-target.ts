import { modifier } from 'ember-modifier';

export default modifier(function dropTarget(
  element,
  [handler]: [(files: FileList) => void],
  { enter, leave }: { enter?: (e: DragEvent) => void; leave?: (e: DragEvent) => void } = {},
) {
  element.addEventListener(
    'dragover',
    preventDefault((e) => {
      (e as DragEvent).dataTransfer!.dropEffect = 'copy';
    }),
  );

  element.addEventListener(
    'drop',
    preventDefault((e) => {
      const _e = e as DragEvent;

      handler(_e.dataTransfer!.files);
      leave?.(_e);
    }),
  );

  element.addEventListener(
    'dragenter',
    preventDefault((e) => {
      enter?.(e as DragEvent);
    }),
  );

  element.addEventListener(
    'dragleave',
    preventDefault((e) => {
      if (e.target !== element) return;

      leave?.(e as DragEvent);
    }),
  );
});

function preventDefault(fn: (e: Event) => void) {
  return (e: Event) => {
    e.stopPropagation();
    e.preventDefault();

    fn(e);
  };
}

import { modifier } from 'ember-modifier';

export default modifier(function dropTarget(
  element: Element,
  [handler]: [(files: FileList) => void],
  { enter, leave }: { enter?: (e: DragEvent) => void; leave?: (e: DragEvent) => void } = {},
) {
  element.addEventListener(
    'dragover',
    preventDefault((e: DragEvent) => {
      e.dataTransfer!.dropEffect = 'copy';
    }),
  );

  element.addEventListener(
    'drop',
    preventDefault((e: DragEvent) => {
      handler(e.dataTransfer!.files);

      leave?.(e);
    }),
  );

  element.addEventListener('dragenter', preventDefault(enter));

  element.addEventListener(
    'dragleave',
    preventDefault((e: DragEvent) => {
      if (e.target !== element) return;

      leave?.(e);
    }),
  );
});

function preventDefault(fn?: (e: DragEvent) => void) {
  return (e: Event) => {
    e.stopPropagation();
    e.preventDefault();

    fn?.(e as DragEvent);
  };
}

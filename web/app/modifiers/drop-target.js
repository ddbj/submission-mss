import { modifier } from 'ember-modifier';

export default modifier(function dropTarget(element, [handler], { enter, leave } = {}) {
  element.addEventListener('dragover', preventDefault((e) => {
    e.dataTransfer.dropEffect = 'copy';
  }));

  element.addEventListener('drop', preventDefault((e) => {
    handler(e.dataTransfer.files);

    leave?.(e);
  }));

  element.addEventListener('dragenter', preventDefault(enter));

  element.addEventListener('dragleave', preventDefault((e) => {
    if (e.target !== element) return;

    leave?.(e);
  }));
});

function preventDefault(fn) {
  return (e) => {
    e.stopPropagation();
    e.preventDefault();

    fn?.(e);
  };
}

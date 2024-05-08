import { modifier } from 'ember-modifier';

export default modifier((_element, _positional, {disabled}) => {
  if (disabled) { return; }

  function preventUnload(event) {
    event.preventDefault();
    event.returnValue = '';
  }

  window.addEventListener('beforeunload', preventUnload);

  return () => window.removeEventListener('beforeunload', preventUnload);
});

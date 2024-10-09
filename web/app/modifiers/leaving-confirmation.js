import { modifier } from 'ember-modifier';

export default modifier(() => {
  function preventUnload(event) {
    event.preventDefault();
    event.returnValue = '';
  }

  window.addEventListener('beforeunload', preventUnload);

  return () => window.removeEventListener('beforeunload', preventUnload);
});

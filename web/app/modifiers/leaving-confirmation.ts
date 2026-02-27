import { modifier } from 'ember-modifier';

export default modifier(() => {
  function preventUnload(event: BeforeUnloadEvent) {
    event.preventDefault();
    event.returnValue = '';
  }

  window.addEventListener('beforeunload', preventUnload);

  return () => window.removeEventListener('beforeunload', preventUnload);
});

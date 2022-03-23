import { modifier } from 'ember-modifier';

export default modifier(() => {
  function errorHandler(error) {
    alert(`Something went wrong: ${error.message}`);

    throw error;
  }

  window.addEventListener('error', errorHandler);

  return () => window.removeEventListener('error', errorHandler);
});

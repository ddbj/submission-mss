import { modifier } from 'ember-modifier';

export default modifier(() => {
  function errorHandler(error) {
    alert(`Error: ${error.message}`);

    throw error;
  }

  function unhandledRejectionHandler(event) {
    alert(`Error: ${event.reason}`);

    // PromiseRejectionEvent will be output to console.
  }

  window.addEventListener('error', errorHandler);
  window.addEventListener('unhandledrejection', unhandledRejectionHandler);

  return () => {
    window.removeEventListener('error', errorHandler);
    window.removeEventListener('unhandledrejection', unhandledRejectionHandler);
  }
});

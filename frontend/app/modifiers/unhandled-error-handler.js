import { modifier } from 'ember-modifier';

export default modifier(() => {
  function errorHandler(error) {
    alert(`Error: ${error.message}`);

    throw error;
  }

  function unhandledRejectionHandler(event) {
    const {reason} = event;
    const message = reason instanceof String ? reason : reason.message || JSON.stringify(reason);

    alert(`Error: ${message}`);

    // PromiseRejectionEvent will be output to console.
  }

  window.addEventListener('error', errorHandler);
  window.addEventListener('unhandledrejection', unhandledRejectionHandler);

  return () => {
    window.removeEventListener('error', errorHandler);
    window.removeEventListener('unhandledrejection', unhandledRejectionHandler);
  }
});

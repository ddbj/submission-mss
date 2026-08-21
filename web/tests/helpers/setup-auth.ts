import { worker } from '../msw/worker';
import { http } from '../msw/http';

// Answers for the session the way the API does: the browser holds a cookie the
// application cannot see, so being signed in is whatever /me says it is.
export function setupAuthentication(hooks: NestedHooks) {
  hooks.beforeEach(() => {
    worker.use(
      http.get('/me', ({ response }) => {
        return response(200).json({ uid: 'alice', csrf_token: 'test-csrf-token' });
      }),
    );
  });
}

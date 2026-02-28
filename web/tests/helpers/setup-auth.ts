export function setupAuthentication(hooks: NestedHooks) {
  hooks.beforeEach(() => {
    localStorage.setItem('token', 'test-token');
  });

  hooks.afterEach(() => {
    localStorage.removeItem('token');
  });
}

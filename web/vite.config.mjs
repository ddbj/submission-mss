import { defineConfig } from 'vite';
import { extensions, classicEmberSupport, ember } from '@embroider/vite';
import { babel } from '@rollup/plugin-babel';
import { loadTranslations } from '@ember-intl/vite';

export default defineConfig({
  // Emit source maps so Sentry can de-minify production stack traces. The app
  // is served over a public path, so Sentry resolves the .map files from their
  // sourceMappingURL — no upload step or auth token required.
  build: {
    sourcemap: true,
  },

  plugins: [
    classicEmberSupport(),
    ember(),
    // extra plugins here
    babel({
      babelHelpers: 'runtime',
      extensions,
    }),
    loadTranslations(),
  ],
});

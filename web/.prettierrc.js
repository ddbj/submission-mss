'use strict';

module.exports = {
  printWidth: 120,
  plugins: ['prettier-plugin-ember-template-tag'],

  overrides: [
    {
      files: '*.{js,ts,gjs,gts}',
      options: {
        singleQuote: true,
      },
    },
  ],
};

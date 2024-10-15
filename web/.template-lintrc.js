'use strict';

module.exports = {
  extends: 'recommended',

  rules: {
    // 'no-bare-strings': true,
    'no-curly-component-invocation': { allow: ['user-mass-dir'] },
    'no-implicit-this': { allow: ['user-mass-dir'] },
    'no-inline-styles': 'off',
  },
};

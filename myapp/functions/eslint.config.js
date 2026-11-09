const js = require('@eslint/js');
const { defineConfig } = require('eslint/config');
const globals = require('globals');

module.exports = defineConfig([
  { ignores: ['node_modules/**'] },
  js.configs.recommended,
  {
    files: ['**/*.js'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'commonjs',
      globals: globals.node,
    },
  },
]);

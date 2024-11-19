module.exports = [
  {
    files: ['**/*.js'], // Apply to all JavaScript files
    languageOptions: {
      ecmaVersion: 2018, // ECMAScript version
      globals: {
        Atomics: 'readonly',
        SharedArrayBuffer: 'readonly',
        window: true,
        alert: true,
        console: true,
        document: true,
        localStorage: true,
        setInterval: true,
        setTimeout: true,
        clearTimeout: true,
        clearInterval: true,
        $: true,
        d3: true,
        App: true,
        L: true,
      },
    },
    rules: {
      indent: ['warn', 2],
      'linebreak-style': ['warn', 'unix'],
      quotes: ['warn', 'single'],
      semi: ['warn', 'always'],
    },
  },
];

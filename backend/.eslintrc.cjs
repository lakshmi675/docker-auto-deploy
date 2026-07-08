module.exports = {
  root: true,
  env: { node: true, es2021: true, commonjs: true },
  extends: ['eslint:recommended'],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'script'
  },
  rules: {
    'no-unused-vars': ['warn', { args: 'none' }]
  }
};

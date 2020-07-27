module.exports = {
    'env': {
        'browser': false,
        'es6': true
    },
    'extends': 'eslint:recommended',
    'globals': {
        "Atomics": "readonly",
        "SharedArrayBuffer": "readonly",
        "window": true,
        "alert": true,
        "console": true,
        "document": true,
        "localStorage": true,
        "setInterval": true,
        "setTimeout": true,
        "clearTimeout": true,
        "clearInterval": true,
        "$": true,
        "d3": true,
        "App": true,
        "L": true
    },
    'parserOptions': {
        'ecmaVersion': 2018
    },
    'rules': {
        'indent': [
            'warn',
            2
        ],
        'linebreak-style': [
            'warn',
            'unix'
        ],
        'quotes': [
            'warn',
            'single'
        ],
        'semi': [
            'warn',
            'always'
        ]
    }
};

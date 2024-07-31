const severity = {
  disable: 0,
  warn: 1,
  error: 2,
}

export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      severity.error,
      'always',
      [
        'build',
        'chore',
        'misc',
        'other',
        'ci',
        'docs',
        'feat',
        'fix',
        'perf',
        'refactor',
        'revert',
        'style',
        'test',
      ],
    ],
  },
}

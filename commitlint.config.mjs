const disable = 0
const warn = 1
const error = 2

export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      error,
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
    'subject-case': [disable]
  },
}

const disable = 0
const warn = 1
const error = 2

export default {
  rules: {
    'type-enum': [
      error,
      'always',
      [
        'feat',
        'fix',
        'perf',
        'build',
        'conf',
        'test',
        'docs',
        'ci',
        'chore',
        'refactor',
        'revert',
        'style',
        'misc',
        'other',
      ],
    ],
    'subject-case': [disable]
  },
}

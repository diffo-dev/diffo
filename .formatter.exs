# Used by "mix format"
locals_without_parens = [
  id: 1,
  category: 1,
  is_enabled?: 1,
  characteristic: 2,
  pick: 1,
  rename: 1,
  field: 3,
  expect: 1,
  relate: 1,
  translate: 1,
  guard: 1,
  customize: 1,
  order: 1,
  initial_states: 1,
  default_initial_state: 1,
  state_attribute: 1,
  transition: 1
]

[
  plugins: [Spark.Formatter],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [:ash],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]

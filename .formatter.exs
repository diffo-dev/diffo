# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

# Used by "mix format"
spark_locals_without_parens = [
  calculate: 1,
  category: 1,
  characteristic: 2,
  characteristic: 3,
  constraints: 1,
  create: 1,
  create: 2,
  description: 1,
  feature: 1,
  feature: 2,
  id: 1,
  is_enabled?: 1,
  major_version: 1,
  minor_version: 1,
  name: 1,
  parties: 2,
  parties: 3,
  party: 2,
  party: 3,
  patch_version: 1,
  place: 2,
  place: 3,
  places: 2,
  places: 3,
  reference: 1,
  role: 2,
  role: 3,
  tmf_version: 1,
  type: 1,
  update: 1,
  update: 2
]

[
  plugins: [Spark.Formatter],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [:ash, :ash_jason, :ash_neo4j, :ash_outstanding, :ash_state_machine],
  locals_without_parens: spark_locals_without_parens,
  export: [
    locals_without_parens: spark_locals_without_parens
  ]
]

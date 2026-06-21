# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

import Config

config :spark,
  formatter: [
    remove_parens?: true,
    "Ash.Resource": [
      section_order: [
        :resource,
        :code_interface,
        :specification,
        :features,
        :characteristics,
        :neo4j,
        :jason,
        :outstanding,
        :actions,
        :state_machine,
        :attributes,
        :relationships,
        :identities,
        :aggregates,
        :calculations,
        :preparations
      ]
    ],
    "Ash.TypedStruct": [
      section_order: [
        :jason,
        :outstanding,
        :fields
      ]
    ]
  ]

config :ash, :custom_expressions, [Diffo.Unwrap.AshCustomExpression]

# AshNeo4j 0.10.0 advertises atomic update/destroy support (Cypher `SET`/bulk queries),
# so Ash now enforces `require_atomic?` by default. Diffo is a graph domain where almost
# every mutating action manages edges (`manage_relationship` → before_action hooks) or runs
# `present`/state-machine validations that have no atomic form, so atomic-by-default is the
# wrong default here. Disable it globally to restore the pre-0.10.0 read-modify-write path;
# hot-path simple-attribute actions can opt back into atomic individually if it ever pays.
config :ash, :require_atomic_by_default?, false

config :diffo, ash_domains: [Diffo.Provider]

# git_ops drives releases: `mix git_ops.release` reads Conventional Commits since the
# last `v*` tag, bumps `@version` in mix.exs, rolls CHANGELOG.md (inserting after the
# `<!-- changelog -->` marker), commits, and tags. Only `feat` and `fix` surface in the
# changelog; `deps` is a custom section for dependency bumps. `chore`/`refactor`/`test`/
# `docs` are accepted commit types but hidden from the changelog (so test-only work like
# verifier coverage doesn't appear). See AGENTS.md "Releasing".
#
# `:git_ops` is `only: [:dev]`, so its config is scoped to :dev — otherwise test/prod
# emit "configured application :git_ops ... but the application is not available".
if config_env() == :dev do
  config :git_ops,
    mix_project: Mix.Project.get!(),
    changelog_file: "CHANGELOG.md",
    repository_url: "https://github.com/diffo-dev/diffo",
    types: [
      deps: [header: "Dependencies"],
      chore: [hidden?: true],
      refactor: [hidden?: true],
      test: [hidden?: true],
      docs: [hidden?: true]
    ],
    tags: [allowed: ["major", "minor", "patch"], allow_untagged?: true],
    manage_mix_version?: true,
    version_tag_prefix: "v"
end

import_config "#{config_env()}.exs"

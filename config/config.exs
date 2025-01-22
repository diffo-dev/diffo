import Config
config :spark, formatter: ["Ash.Resource": [section_order: [:postgres]]]
config :diffo, ecto_repos: [Diffo.Repo], ash_domains: [Diffo.Provider]
import_config "#{config_env()}.exs"

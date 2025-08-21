import Config
config :spark, formatter: ["Ash.Resource": [section_order: [:neo4j, :jason, :outstanding]]]
config :diffo, ash_domains: [Diffo.Provider, Diffo.Access]
import_config "#{config_env()}.exs"

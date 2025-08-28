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

config :diffo, ash_domains: [Diffo.Provider, Diffo.Access]
import_config "#{config_env()}.exs"

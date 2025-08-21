defmodule Diffo.Provider.Instance.Extension do
  @moduledoc """
  DSL Extension customising an Instance
  """

  @specification %Spark.Dsl.Section{
    name: :specification,
    describe: "Defines the Instance Specification",
    examples: [
      """
      specification do
        id "da9b207a-26c3-451d-8abd-0640c6349979"
        name "DSL Access Service"
        major_version 1
        description "An access network service connecting a subscriber premises to an access NNI via DSL"
        category :network_service
      end
      """
    ],
    schema: [
      id: [
        type: :string,
        doc: """
        The id of the specification, a uuid4 the same in all environments, unique for name and major_version.
        """,
        required: true
      ],
      name: [
        type: :string,
        doc: """
        The name of the specification, unique to a service but common for all versions.
        """,
        required: true
      ],
      major_version: [
        type: :integer,
        doc: """
        The major_version of the specification.
        """,
        default: 1
      ],
      description: [
        type: :string,
        doc: """
        A generic description of the specified service or resource.
        """
      ],
      category: [
        type: :atom,
        doc: """
        The category the specified service or resource belongs to.
        """
      ],
    ]
  }

  @characteristic %Spark.Dsl.Entity{
    name: :characteristic,
    describe: "Adds a Characteristic",
    target: Diffo.Provider.CharacteristicSpecification,
    args: [:name, :value_type],
    schema: [
      name: [
        doc: """
          The name of the characteristic, an atom
        """,
        type: :atom,
        required: true,
      ],
      value_type: [
        doc: """
          The optional type of the characteristic's value, an atom, may be a module name such as an Ash.TypedStruct
        """,
        type: :atom
      ]
    ]
  }

  @characteristics %Spark.Dsl.Section{
    name: :characteristics,
    describe: """
      List of Characteristics.
    """,
    entities: [
      characteristic: @characteristic
    ]
  }

  @feature %Spark.Dsl.Entity{
    name: :feature,
    describe: """
      Adds a Feature
    """,
    target: Diffo.Provider.FeatureSpecification,
    args: [:name],
    schema: [
      name: [
        doc: """
          The name of the feature, an atom
        """,
        type: :atom,
        required: true,
      ],
      is_enabled?: [
        doc: """
          Whether the feature is enabled by default, defaults true
        """,
        type: :boolean
      ]
    ],
    entities: [
      characteristics: @characteristics
    ]
  }

  @features %Spark.Dsl.Section{
    name: :features,
    describe: """
      Configuration for Instance Features.
    """,
    entities: [
      feature: @feature
    ]
  }

  use Spark.Dsl.Extension,
    sections: [@specification] #@characteristics, @features
      #transformers: [Diffo.Provider.InstanceStructure.Transformer]
end

defmodule Diffo.Provider.Entity do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference
  Copyright Matt Beanland beanland@live.com.au

  Entity - Ash Resource for a TMF Entity
  """
  use Ash.Resource,
    otp_app: :diffo,
    domain: Diffo.Provider,
    data_layer: AshNeo4j.DataLayer,
    extensions: [AshJason.Resource]

  neo4j do
    label(:Entity)
    relate [
      {:entity_refs, :RELATED_HOW, :incoming}
    ]
    translate(id: :uuid)
  end

  jason do
    pick([:id, :href, :name, :referredType, :type])
    rename(referredType: "@referredType", type: "@type")
  end

  attributes do
    attribute :id, :string do
      description "the unique id of the entity"
      primary_key? true
      allow_nil? false
      public? true
    end

    attribute :href, :string do
      description "the href of the entity"
      allow_nil? true
      public? true
    end

    attribute :name, :string do
      description "the name of the entity"
      allow_nil? true
      public? true
      constraints match: ~r/^[a-zA-Z0-9\s._-]+$/
    end

    attribute :type, :atom do
      description "the type of the entity"
      allow_nil? false
      public? true
      default :EntityRef
    end

    attribute :referredType, :atom do
      description "the type of the entity"
      allow_nil? true
      public? true
    end

    create_timestamp :inserted_at

    update_timestamp :updated_at
  end

  relationships do
    has_many :entity_refs, Diffo.Provider.EntityRef do
      destination_attribute :entity_id
      public? true
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      description "creates a entity"
      accept [:id, :href, :name, :type, :referredType]
      upsert? true
    end

    read :find_by_name do
      description "finds entity by name"
      get? false

      argument :query, :ci_string do
        description "Return only parties with names including the given value."
      end

      filter expr(contains(name, ^arg(:query)))
    end

    read :list do
      description "lists all parties"
    end

    update :update do
      description "updates the entity"
      accept [:href, :name, :type, :referredType]
    end
  end

  preparations do
    prepare build(sort: [id: :asc])
  end

  validations do
    validate {Diffo.Validations.HrefEndsWithId, id: :id, href: :href} do
      where [present(:id), present(:href)]
    end

    validate attribute_equals(:type, :EntityRef) do
      where present(:referredType)
      message "when referredType is present, type must be EntityRef"
    end

    validate attribute_does_not_equal(:type, :EntityRef) do
      where absent(:referredType)
      message "when referredType is absent, type must be not be EntityRef"
    end
  end

  @doc """
  Compares two entity, by ascending id
  ## Examples
    iex> Diffo.Provider.Entity.compare(%{id: "a"}, %{id: "a"})
    :eq
    iex> Diffo.Provider.Entity.compare(%{id: "b"}, %{id: "a"})
    :gt
    iex> Diffo.Provider.Entity.compare(%{id: "a"}, %{id: "b"})
    :lt

  """
  def compare(%{id: id0}, %{id: id1}), do: Diffo.Util.compare(id0, id1)
end

defmodule Diffo.Provider.Place do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference
  Copyright Matt Beanland beanland@live.com.au

  Place - Ash Resource for a TMF Place
  """
  use Ash.Resource, otp_app: :diffo, domain: Diffo.Provider, data_layer: AshPostgres.DataLayer, extensions: [AshJason.Resource]

  postgres do
    table "places"
    repo Diffo.Repo
  end

  jason do
    rename %{:referredType => "@referredType", :type => "@type"}
    order [:id, :href, :name, "@referredType", "@type"]
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      description "creates a place"
      accept [:id, :href, :name, :type, :referredType ]
    end

    read :find_by_name do
      description "finds place by name"
      get? false
      argument :query, :ci_string do
        description "Return only places with names including the given value."
      end
      filter expr(contains(name, ^arg(:query)))
    end

    read :list do
      description "lists all places"
    end

    update :update do
      description "updates the place"
      accept [:href, :name, :type, :referredType]
    end
  end

  attributes do
    attribute :id, :string do
      description "the unique id of the place"
      primary_key? true
      allow_nil? false
      public? true
    end

    attribute :href, :string do
      description "the href of the place"
      allow_nil? true
      public? true
    end

    attribute :name, :string do
      description "the name of the place"
      allow_nil? true
      public? true
      constraints match: ~r/^[a-zA-Z0-9\s._-]+$/
    end

    attribute :type, :atom do
      description "the type of the place"
      allow_nil? false
      public? true
      default :PlaceRef
      constraints one_of: [:PlaceRef, :GeographicSite, :GeographicLocation, :GeographicAddress]
    end

    attribute :referredType, :atom do
      description "the type of the place"
      allow_nil? true
      public? true
      constraints one_of: [:GeographicSite, :GeographicLocation, :GeographicAddress]
    end

    create_timestamp :inserted_at

    update_timestamp :updated_at
  end

  validations do
    validate {Diffo.Validations.HrefEndsWithId, id: :id, href: :href} do
      where [present(:id), present(:href)]
    end

    validate attribute_equals(:type, :PlaceRef) do
      where present(:referredType)
      message "when referredType is present, type must be PlaceRef"
    end

    validate attribute_does_not_equal(:type, :PlaceRef) do
      where absent(:referredType)
      message "when referredType is absent, type must be not be PlaceRef"
    end
  end

  relationships do
    has_many :place_refs, Diffo.Provider.PlaceRef do
      destination_attribute :place_id
      public? true
    end
  end

  preparations do
    prepare build(sort: [id: :asc])
  end

  @doc """
  Compares two place, by ascending id
  ## Examples
    iex> Diffo.Provider.Place.compare(%{id: "a"}, %{id: "a"})
    :eq
    iex> Diffo.Provider.Place.compare(%{id: "b"}, %{id: "a"})
    :gt
    iex> Diffo.Provider.Place.compare(%{id: "a"}, %{id: "b"})
    :lt

  """
  def compare(%{id: id0}, %{id: id1}), do: Diffo.Util.compare(id0, id1)
end

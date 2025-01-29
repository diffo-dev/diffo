defmodule Diffo.Provider.Relationship_Test do
  @moduledoc false
  use ExUnit.Case
  use Diffo.DataCase, async: true

  describe "Diffo.Provider prepare Relationships" do
    test "check there are no relationships" do
      assert Diffo.Provider.list_relationships!() == []
    end
  end

  describe "Diffo.Provider create Relationships" do
    test "create a mutual peer service relationship" do
      specification = Diffo.Provider.create_specification!(%{name: "accessEvc"})
      evpl1 = Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "evpl1"})
      evpl2 = Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "evpl2"})
      relationship = Diffo.Provider.create_relationship!(%{type: :refersTo, reverse_type: :refersTo, source_id: evpl1.id, target_id: evpl2.id})
      assert relationship.id != evpl1.id
      assert relationship.id != evpl2.id
    end
  end

  describe "Diffo.Provider cleanup Relationships" do
    test "ensure there are no relationships" do
      for relationship <- Diffo.Provider.list_relationships!() do
        Diffo.Provider.delete_relationship!(%{id: relationship.id})
      end
      assert Diffo.Provider.list_relationships!() == []
    end

    test "ensure there are no instances" do
      for instance <- Diffo.Provider.list_instances!() do
        Diffo.Provider.delete_instance!(%{id: instance.id})
      end
      assert Diffo.Provider.list_instances!() == []
    end

    test "ensure there are no specifications" do
      for specification <- Diffo.Provider.list_specifications!() do
        Diffo.Provider.delete_specification!(%{id: specification.id})
      end
      assert Diffo.Provider.list_specifications!() == []
    end
  end
end

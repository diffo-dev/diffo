defmodule Diffo.Provider.Specification_Test do
  @moduledoc false
  use ExUnit.Case
  require Ash.Query

  test "create a service specification - success - name only supplied" do
    {:ok, specification} = Diffo.Provider.create_specification(%{name: "adslAccess"})
    assert specification.name == "adslAccess"
    assert Diffo.Uuid.uuid4?(specification.id) == true
    assert specification.major_version == 1
    assert specification.type == :serviceSpecification
    {:ok, loaded_specification} = Diffo.Provider.get_specification_by_id(specification.id, load: [:version, :href])
    assert loaded_specification.version == "v1.0.0"
    assert loaded_specification.href == "serviceCatalogManagement/v4/serviceSpecification/#{specification.id}"
  end

  test "create a service specification - success - name and type supplied" do
    {:ok, specification} = Diffo.Provider.create_specification(%{name: "adslAccess", type: :serviceSpecification})
    assert specification.name == "adslAccess"
    assert specification.type == :serviceSpecification
  end

  test "create a resource specification - success - name and type supplied" do
    {:ok, specification} = Diffo.Provider.create_specification(%{name: "can", type: :resourceSpecification})
    assert specification.name == "can"
    assert specification.type == :resourceSpecification
    {:ok, loaded_specification} = Diffo.Provider.get_specification_by_id(specification.id, load: [:version, :href])
    assert loaded_specification.version == "v1.0.0"
    assert loaded_specification.href == "resourceCatalogManagement/v4/resourceSpecification/#{specification.id}"
  end

  test "create a service specification - success - name and id supplied" do
    uuid = UUID.uuid4()
    {:ok, specification} = Diffo.Provider.create_specification(%{name: "adslAccess", id: uuid})
    assert specification.id == uuid

    {:ok, loaded_specification} = Diffo.Provider.get_specification_by_id(uuid, load: :href)
    assert loaded_specification.href == "serviceCatalogManagement/v4/serviceSpecification/#{uuid}"
  end

  test "create a service specification - success - name and major_version supplied" do
    {:ok, specification} = Diffo.Provider.create_specification(%{name: "adslAccess", major_version: 2})
    assert specification.major_version == 2
    {:ok, loaded_specification} = Diffo.Provider.get_specification_by_id(specification.id, load: :version)
    assert loaded_specification.version == "v2.0.0"
  end

  test "create a service specification - failure - no name" do
    {:error, _specification} = Diffo.Provider.create_specification(%{})
  end

  test "create a service specification - failure - name not camelCase" do
    {:error, _specification} = Diffo.Provider.create_specification(%{name: "adsl access"})
  end

  test "create a service specification - failure - id not uuidv4" do
    {:error, _specification} = Diffo.Provider.create_specification(%{name: "adslAccess", id: "123"})
  end

  test "create a service specification - failure - type not correct" do
    {:error, _specification} = Diffo.Provider.create_specification(%{name: "adslAccess", type: :service})
  end

  test "update the description of a specification - success" do
    {:ok, specification} = Diffo.Provider.create_specification(%{name: "adslAccess", description: "ADSL Access Service"})
    assert specification.description == "ADSL Access Service"
    {:ok, updated_specification} = specification |> Diffo.Provider.describe_specification(%{description: "Asymmetric DSL Access Service"})
    assert updated_specification.description == "Asymmetric DSL Access Service"
  end

  test "make a new patch version - success" do
    {:ok, specification} = Diffo.Provider.create_specification(%{name: "adslAccess", description: "ADSL Access Service"})
    {:ok, updated_specification} = specification |> Diffo.Provider.next_patch_specification(load: :version)
    assert updated_specification.version == "v1.0.1"
  end

  test "make a new minor version, resetting the patch version - success" do
    {:ok, specification} = Diffo.Provider.create_specification(%{name: "adslAccess", description: "ADSL Access Service"})
    {:ok, patched_specification} = specification |> Diffo.Provider.next_patch_specification(load: :version)
    {:ok, updated_specification} = patched_specification |> Diffo.Provider.next_minor_specification(load: :version)
    assert updated_specification.version == "v1.1.0"
  end

  test "make a new patch on an minor version - success" do
    {:ok, specification} = Diffo.Provider.create_specification(%{name: "adslAccess", description: "ADSL Access Service"})
    {:ok, updated_specification} = specification |> Diffo.Provider.next_minor_specification(load: :version)
    {:ok, patched_specification} = updated_specification |> Diffo.Provider.next_patch_specification(load: :version)
    assert patched_specification.version == "v1.1.1"
  end
end

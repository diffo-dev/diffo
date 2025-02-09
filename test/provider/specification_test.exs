defmodule Diffo.Provider.SpecificationTest do
  @moduledoc false
  use ExUnit.Case
  use Diffo.DataCase, async: true

  describe "Diffo.Provider read Specifications!" do
   test "find specifications by category" do
      Diffo.Provider.create_specification!(%{name: "compute", category: "cloud"})
      Diffo.Provider.create_specification!(%{name: "storage", category: "cloud"})
      Diffo.Provider.create_specification!(%{name: "intelligence", category: "cloud"})
      specifications = Diffo.Provider.find_specifications_by_category!("cloud")
      assert length(specifications) == 3
    end

    test "find specifications by name" do
      Diffo.Provider.create_specification!(%{name: "transport"})
      Diffo.Provider.create_specification!(%{name: "transport", major_version: 2})
      Diffo.Provider.create_specification!(%{name: "transport", major_version: 3})
      specifications = Diffo.Provider.find_specifications_by_name!("transport")
      assert length(specifications) == 3
    end

    test "get latest specification" do
      Diffo.Provider.create_specification!(%{name: "edge"})
      Diffo.Provider.create_specification!(%{name: "edge", major_version: 2})
      Diffo.Provider.create_specification!(%{name: "edge", major_version: 3})
      latest = Diffo.Provider.get_latest_specification_by_name!("edge")
      assert latest.major_version == 3
      assert latest.version == "v3.0.0"
    end
  end

  describe "Diffo.Provider create Specifications" do
    test "create a service specification - success - name only supplied" do
      specification = Diffo.Provider.create_specification!(%{name: "adslAccess"})
      assert specification.name == "adslAccess"
      assert Diffo.Uuid.uuid4?(specification.id) == true
      assert specification.major_version == 1
      assert specification.type == :serviceSpecification
      assert loaded_specification = Diffo.Provider.get_specification_by_id!(specification.id)
      assert loaded_specification.version == "v1.0.0"
      assert loaded_specification.href == "serviceCatalogManagement/v4/serviceSpecification/#{specification.id}"
      assert loaded_specification.instance_type == :service
    end

    test "create a service specification - success - name and type supplied" do
      specification = Diffo.Provider.create_specification!(%{name: "broadband", type: :serviceSpecification})
      assert specification.name == "broadband"
      assert specification.type == :serviceSpecification
    end

    test "create a resource specification - success - name and type supplied" do
      specification = Diffo.Provider.create_specification!(%{name: "can", type: :resourceSpecification})
      assert specification.name == "can"
      assert specification.type == :resourceSpecification
      assert loaded_specification = Diffo.Provider.get_specification_by_id!(specification.id)
      assert loaded_specification.version == "v1.0.0"
      assert loaded_specification.href == "resourceCatalogManagement/v4/resourceSpecification/#{specification.id}"
      assert loaded_specification.instance_type == :resource
    end

    test "create a service specification - success - name and id supplied" do
      uuid = UUID.uuid4()
      specification = Diffo.Provider.create_specification!(%{name: "siteConnection", id: uuid})
      assert specification.id == uuid
      assert loaded_specification = Diffo.Provider.get_specification_by_id!(specification.id)
      assert loaded_specification.href == "serviceCatalogManagement/v4/serviceSpecification/#{uuid}"
    end

    test "create a service specification - success - name and major_version supplied" do
      specification = Diffo.Provider.create_specification!(%{name: "adslAccess", major_version: 2})
      assert specification.major_version == 2
      assert loaded_specification = Diffo.Provider.get_specification_by_id!(specification.id)
      assert loaded_specification.version == "v2.0.0"
    end

    test "create a service specification - failure - no name" do
      {:error, _specification} = Diffo.Provider.create_specification(%{})
    end

    test "create a service specification - failure - name not camelCase" do
      {:error, _specification} = Diffo.Provider.create_specification(%{name: "adsl access"})
    end

    test "create a service specification - failure - id not uuidv4" do
      {:error, _specification} = Diffo.Provider.create_specification(%{name: "device", id: "123"})
    end

    test "create a service specification - failure - type not correct" do
      {:error, _specification} = Diffo.Provider.create_specification(%{name: "aggregation", type: :service})
    end

    test "create a service specification - failure - name and major version not unique" do
      Diffo.Provider.create_specification!(%{name: "voice"})
      {:error, _specification} = Diffo.Provider.create_specification(%{name: "voice"})
    end
  end

  describe "Diffo.Provider update Specifications" do
    test "update the description of a specification - success" do
      specification = Diffo.Provider.create_specification!(%{name: "adsl", description: "ADSL Access Service"})
      assert specification.description == "ADSL Access Service"
      updated_specification = specification |> Diffo.Provider.describe_specification!(%{description: "Asymmetric DSL Access Service"})
      assert updated_specification.description == "Asymmetric DSL Access Service"
    end

    test "make a new patch version - success" do
      specification = Diffo.Provider.create_specification!(%{name: "connectivity"})
      updated_specification = specification |> Diffo.Provider.next_patch_specification!()
      assert updated_specification.version == "v1.0.1"
    end

    test "make a new minor version, resetting the patch version - success" do
      updated_specification = Diffo.Provider.create_specification!(%{name: "security"})
        |> Diffo.Provider.next_patch_specification!()
        |> Diffo.Provider.next_minor_specification!()
      assert updated_specification.version == "v1.1.0"
    end

    test "make a new patch on an minor version - success" do
      patched_specification = Diffo.Provider.create_specification!(%{name: "monitoring"})
        |> Diffo.Provider.next_minor_specification!()
        |> Diffo.Provider.next_patch_specification!()
      assert patched_specification.version == "v1.1.1"
    end
  end

  describe "Diffo.Provider encode Specifications" do
    test "encode json - success" do
      uuid = UUID.uuid4()
      specification = Diffo.Provider.create_specification!(%{name: "radiationMonitor", description: "Radiation Monitoring Service", id: uuid})
      loaded_specification = Diffo.Provider.get_specification_by_id!(specification.id)
      encoding = Jason.encode!(loaded_specification)
      assert encoding == ~s({\"id\":\"#{uuid}\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/#{uuid}\",\"name\":\"radiationMonitor\",\"version\":\"v1.0.0\"})
    end
  end

  describe "Diffo.Provider delete Specifications" do
    test "bulk delete" do
      Diffo.Provider.delete_specification!(Diffo.Provider.list_specifications!())
    end
  end
end

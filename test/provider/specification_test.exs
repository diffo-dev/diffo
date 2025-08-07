defmodule Diffo.Provider.SpecificationTest do
  @moduledoc false
  use ExUnit.Case

  setup_all do
    AshNeo4j.BoltxHelper.start()
  end

  setup do
    on_exit(fn ->
      AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  describe "Diffo.Provider read Specifications!" do
    test "list specifications" do
      Diffo.Provider.create_specification!(%{name: "compute", category: "cloud"})
      Diffo.Provider.create_specification!(%{name: "storage", category: "cloud"})
      Diffo.Provider.create_specification!(%{name: "intelligence", category: "agent"})
      specifications = Diffo.Provider.list_specifications!()
      assert length(specifications) == 3
    end

    test "find specifications by category" do
      Diffo.Provider.create_specification!(%{name: "compute", category: "cloud"})
      Diffo.Provider.create_specification!(%{name: "storage", category: "cloud"})
      Diffo.Provider.create_specification!(%{name: "intelligence", category: "agent"})
      specifications = Diffo.Provider.find_specifications_by_category!("cloud")
      assert length(specifications) == 2
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
      assert specification.version == "v1.0.0"

      assert specification.href ==
               "serviceCatalogManagement/v4/serviceSpecification/#{specification.id}"

      assert specification.instance_type == :service
    end

    test "create a service specification - success - name and type supplied" do
      specification =
        Diffo.Provider.create_specification!(%{name: "broadband", type: :serviceSpecification})

      assert specification.name == "broadband"
      assert specification.type == :serviceSpecification
    end

    test "create a resource specification - success - name and type supplied" do
      specification =
        Diffo.Provider.create_specification!(%{name: "can", type: :resourceSpecification})

      assert specification.name == "can"
      assert specification.type == :resourceSpecification
      assert specification.version == "v1.0.0"

      assert specification.href ==
               "resourceCatalogManagement/v4/resourceSpecification/#{specification.id}"

      assert specification.instance_type == :resource
    end

    test "create a service specification - success - name and id supplied" do
      uuid = UUID.uuid4()
      specification = Diffo.Provider.create_specification!(%{name: "siteConnection", id: uuid})
      assert specification.id == uuid
      assert specification = Diffo.Provider.get_specification_by_id!(specification.id)
      assert specification.href == "serviceCatalogManagement/v4/serviceSpecification/#{uuid}"
    end

    test "create a service specification - success - name and major_version supplied" do
      specification =
        Diffo.Provider.create_specification!(%{name: "adslAccess", major_version: 2})

      assert specification.major_version == 2
      assert specification.version == "v2.0.0"
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
      {:error, _specification} =
        Diffo.Provider.create_specification(%{name: "aggregation", type: :service})
    end

    test "create a Specfication that already exists, preserving attributes - success" do
      specification =
        Diffo.Provider.create_specification!(%{
          name: "adslAccess",
          major_version: 2,
          category: :access
        })

      Diffo.Provider.create_specification!(%{name: "adslAccess", major_version: 2})
      refreshed_specification = Diffo.Provider.get_specification_by_id!(specification.id)
      assert refreshed_specification.category == "access"
    end

    test "create a Specification that already exists, adding attributes - success" do
      specification =
        Diffo.Provider.create_specification!(%{name: "adslAccess", major_version: 2})

      Diffo.Provider.create_specification!(%{
        name: "adslAccess",
        major_version: 2,
        category: :access
      })

      refreshed_specification = Diffo.Provider.get_specification_by_id!(specification.id)
      assert refreshed_specification.category == "access"
    end
  end

  describe "Diffo.Provider update Specifications" do
    test "update the description of a specification - success" do
      specification =
        Diffo.Provider.create_specification!(%{name: "adsl", description: "ADSL Access Service"})

      assert specification.description == "ADSL Access Service"

      updated_specification =
        specification
        |> Diffo.Provider.describe_specification!(%{description: "Asymmetric DSL Access Service"})

      assert updated_specification.description == "Asymmetric DSL Access Service"
    end

    test "make a new patch version - success" do
      specification = Diffo.Provider.create_specification!(%{name: "connectivity"})
      updated_specification = specification |> Diffo.Provider.next_patch_specification!()
      assert updated_specification.version == "v1.0.1"
    end

    test "make a new minor version, resetting the patch version - success" do
      updated_specification =
        Diffo.Provider.create_specification!(%{name: "security"})
        |> Diffo.Provider.next_patch_specification!()
        |> Diffo.Provider.next_minor_specification!()

       assert updated_specification.version == "v1.1.0"
    end

    test "make a new patch on an minor version - success" do
      patched_specification =
        Diffo.Provider.create_specification!(%{name: "monitoring"})
        |> Diffo.Provider.next_minor_specification!()
        |> Diffo.Provider.next_patch_specification!()

      assert patched_specification.version == "v1.1.1"
    end
  end

  describe "Diffo.Provider encode Specifications" do
    test "encode json - success" do
      uuid = UUID.uuid4()

      specification =
        Diffo.Provider.create_specification!(%{
          name: "radiationMonitor",
          description: "Radiation Monitoring Service",
          id: uuid
        })

      encoding = Jason.encode!(specification)

      assert encoding ==
               ~s({\"id\":\"#{uuid}\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/#{uuid}\",\"name\":\"radiationMonitor\",\"version\":\"v1.0.0\"})
    end
  end

  describe "Diffo.Provider outstanding Specification" do
    test "outstanding specification" do
      use Outstand
      version1 = Diffo.Provider.create_specification!(%{name: "access", major_version: 1})
      version1_1 = version1 |> Diffo.Provider.next_minor_specification!()
      version2 = Diffo.Provider.create_specification!(%{name: "access", major_version: 2})
      accessor = Diffo.Provider.create_specification!(%{name: "accessor", major_version: 1})
      assert Outstanding.outstanding?(version1, accessor)
      assert Outstanding.outstanding?(version2, version1)
      assert Outstanding.outstanding?(version1, version2)
      assert Outstand.nil_outstanding?(version1, version1)
      assert Outstand.nil_outstanding?(version1_1, version1_1)
      assert Outstand.nil_outstanding?(version2, version2)
      assert Outstand.nil_outstanding?(version1_1, version1)
      assert Outstand.nil_outstanding?(version1, version1_1)
      # allow either of two major specifications if we have access to reference specifications
      assert Outstand.nil_outstanding?({&Outstand.any_of/2, [version1, version2]}, version1)
      assert Outstand.nil_outstanding?({&Outstand.any_of/2, [version1, version2]}, version2)
      # alternatively we can make specific expectations on name and major version
      assert Outstand.nil_outstanding?("access", version1_1.name)
      assert Outstand.nil_outstanding?(1..2, version1_1.major_version)
      assert Outstand.nil_outstanding?(1..2, version2.major_version)

      # we can separately run outstanding on the minor version, but by default minor version is not included in the Specification outstanding.
      assert Outstand.nil_outstanding?(1..3, version1_1.minor_version)

      # we can separately use regex on version, but by default version is not included in the the Specification outstanding.
      assert Outstand.nil_outstanding?(~r/v[1..2]/, version1_1.version)
      assert Outstand.nil_outstanding?(~r/v[1..2]/, version2.version)
      assert Outstanding.outstanding?(~r/v[1..2]/, "v3.1.0")
    end
  end

  describe "Diffo.Provider delete Specifications" do
    test "delete specification - success" do
      specification = Diffo.Provider.create_specification!(%{name: "shdslAccess"})
      :ok = Diffo.Provider.delete_specification(specification)
      {:error, error} = Diffo.Provider.get_specification_by_id(specification.id)
      assert is_struct(error, Ash.Error.Invalid)
    end

    test "delete specification - failure, related instance" do
      specification = Diffo.Provider.create_specification!(%{name: "bdslAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      {:error, error} = Diffo.Provider.delete_specification(specification)
      assert is_struct(error, Ash.Error.Invalid)

      # now delete the instance and we should be able to delete the specification
      :ok = Diffo.Provider.delete_instance(instance)
      :ok = Diffo.Provider.delete_specification(specification)
    end
  end
end

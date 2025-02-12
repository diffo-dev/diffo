defmodule Diffo.Provider.ProcessStatus.ProcessStatus do
  @moduledoc false
  use ExUnit.Case
  use Diffo.DataCase, async: true

  describe "Diffo.Provider.ProcessStatus create" do
    test "create a process status - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      process_status = Diffo.Provider.ProcessStatus.create!(%{instance_id: instance.id, code: "NBNACC-1003", severity: :WARN, message: "nbnProductOrder cancelled"})
      assert process_status.code == "NBNACC-1003"
    end

    test "create a process status with a parameterised message - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      parameterized_message = %{reason: "cancelled due to force majeure"}
      process_status = Diffo.Provider.ProcessStatus.create!(%{instance_id: instance.id, code: "NBNACC-1003", severity: :WARN, message: "nbnProductOrder cancelled", parameterized_message: parameterized_message})
      assert process_status.code == "NBNACC-1003"
    end
  end

  describe "Diffo.Provider.ProcessStatus update" do
    test "update code - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      process_status = Diffo.Provider.ProcessStatus.create!(%{instance_id: instance.id, code: "NBNACC-1003", severity: :WARN, message: "nbnProductOrder cancelled"})
      updated_process_status = process_status |> Diffo.Provider.ProcessStatus.update!(%{code: "NBNACC-9999"})
      assert updated_process_status.code == "NBNACC-9999"
    end

    test "update severity - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      process_status = Diffo.Provider.ProcessStatus.create!(%{instance_id: instance.id, code: "NBNACC-1003", severity: :WARN, message: "nbnProductOrder cancelled"})
      updated_process_status = process_status |> Diffo.Provider.ProcessStatus.update!(%{severity: :ERROR})
      assert updated_process_status.severity == :ERROR
    end

    test "update message - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      process_status = Diffo.Provider.ProcessStatus.create!(%{instance_id: instance.id, code: "NBNACC-1003", severity: :WARN, message: "nbnProductOrder cancelled"})
      updated_process_status = process_status |> Diffo.Provider.ProcessStatus.update!(%{message: "nbnProductOrder pending"})
      assert updated_process_status.message == "nbnProductOrder pending"
    end

    test "update parameterized message - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      parameterized_message = %{reason: "cancelled due to force majeure"}
      process_status = Diffo.Provider.ProcessStatus.create!(%{instance_id: instance.id, code: "NBNACC-1003", severity: :WARN, message: "nbnProductOrder cancelled"})
      updated_process_status = process_status |> Diffo.Provider.ProcessStatus.update!(%{parameterized_message: parameterized_message})
      assert updated_process_status.parameterized_message == parameterized_message
    end

    test "update code to nil - failure" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      process_status = Diffo.Provider.ProcessStatus.create!(%{instance_id: instance.id, code: "NBNACC-1003", severity: :WARN, message: "nbnProductOrder cancelled"})
      {:error, _error} = process_status |> Diffo.Provider.ProcessStatus.update(%{code: nil})
    end

    test "update severity to nil - failure" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      process_status = Diffo.Provider.ProcessStatus.create!(%{instance_id: instance.id, code: "NBNACC-1003", severity: :WARN, message: "nbnProductOrder cancelled"})
      {:error, _error} = process_status |> Diffo.Provider.ProcessStatus.update(%{severity: nil})
    end

    test "update message to nil - failure" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      process_status = Diffo.Provider.ProcessStatus.create!(%{instance_id: instance.id, code: "NBNACC-1003", severity: :WARN, message: "nbnProductOrder cancelled"})
      {:error, _error} = process_status |> Diffo.Provider.ProcessStatus.update(%{message: nil})
    end

    test "update parameterized message to nil - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      parameterized_message = %{reason: "cancelled due to force majeure"}
      process_status = Diffo.Provider.ProcessStatus.create!(%{instance_id: instance.id, code: "NBNACC-1003", severity: :WARN, message: "nbnProductOrder cancelled", parameterized_message: parameterized_message})
      updated_process_status = process_status |> Diffo.Provider.ProcessStatus.update!(%{parameterized_message: nil})
      assert updated_process_status.parameterized_message == nil
    end
  end

  describe "Diffo.Provider.ProcessStatus encode" do
    test "encode json - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      process_status = Diffo.Provider.ProcessStatus.create!(%{instance_id: instance.id, code: "NBNACC-1003", severity: :WARN, message: "nbnProductOrder cancelled"})
      encoding = Jason.encode!(process_status) |> Diffo.Util.summarise_dates()
      assert encoding == "{\"code\":\"NBNACC-1003\",\"severity\":\"WARN\",\"message\":\"nbnProductOrder cancelled\",\"timeStamp\":\"now\"}"
    end

    test "encode json with parameterized message - success" do
      parameterized_message = %{reason: "cancelled due to force majeure"}
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      process_status = Diffo.Provider.ProcessStatus.create!(%{instance_id: instance.id, code: "NBNACC-1003", severity: :WARN, message: "nbnProductOrder cancelled", parameterized_message: parameterized_message})
      encoding = Jason.encode!(process_status) |> Diffo.Util.summarise_dates()
      assert encoding == "{\"code\":\"NBNACC-1003\",\"severity\":\"WARN\",\"message\":\"nbnProductOrder cancelled\",\"parameterizedMessage\":{\"reason\":\"cancelled due to force majeure\"},\"timeStamp\":\"now\"}"
    end
  end
end

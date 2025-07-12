defmodule Diffo.Provider.ProcessStatus.ProcessStatus do
  @moduledoc false
  use ExUnit.Case

  setup_all do
    AshNeo4j.BoltxHelper.start()
  end

  setup do
    on_exit(fn ->
      AshNeo4j.Neo4jHelper.delete_nodes(:ProcessStatus)
    end)
  end

  describe "Diffo.Provider.ProcessStatus create" do
    test "create a process status - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      process_status =
        Diffo.Provider.ProcessStatus.create!(%{
          instance_id: instance.id,
          code: "NBNACC-1003",
          severity: :WARN,
          message: "nbnProductOrder cancelled"
        })
Ex
      assert process_status.code == "NBNACC-1003"
    end

    test "create a process status with a parameterised message - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})
      parameterized_message = %{reason: "cancelled due to force majeure"}

      process_status =
        Diffo.Provider.ProcessStatus.create!(%{
          instance_id: instance.id,
          code: "NBNACC-1003",
          severity: :WARN,
          message: "nbnProductOrder cancelled",
          parameterized_message: parameterized_message
        })

      assert process_status.code == "NBNACC-1003"
    end
  end

  describe "Diffo.Provider.ProcessStatus update" do
    test "update code - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      process_status =
        Diffo.Provider.ProcessStatus.create!(%{
          instance_id: instance.id,
          code: "NBNACC-1003",
          severity: :WARN,
          message: "nbnProductOrder cancelled"
        })

      updated_process_status =
        process_status |> Diffo.Provider.ProcessStatus.update!(%{code: "NBNACC-9999"})

      assert updated_process_status.code == "NBNACC-9999"
    end

    test "update severity - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      process_status =
        Diffo.Provider.ProcessStatus.create!(%{
          instance_id: instance.id,
          code: "NBNACC-1003",
          severity: :WARN,
          message: "nbnProductOrder cancelled"
        })

      updated_process_status =
        process_status |> Diffo.Provider.ProcessStatus.update!(%{severity: :ERROR})

      assert updated_process_status.severity == :ERROR
    end

    test "update message - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      process_status =
        Diffo.Provider.ProcessStatus.create!(%{
          instance_id: instance.id,
          code: "NBNACC-1003",
          severity: :WARN,
          message: "nbnProductOrder cancelled"
        })

      updated_process_status =
        process_status
        |> Diffo.Provider.ProcessStatus.update!(%{message: "nbnProductOrder pending"})

      assert updated_process_status.message == "nbnProductOrder pending"
    end

    test "update parameterized message - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})
      parameterized_message = %{reason: "cancelled due to force majeure"}

      process_status =
        Diffo.Provider.ProcessStatus.create!(%{
          instance_id: instance.id,
          code: "NBNACC-1003",
          severity: :WARN,
          message: "nbnProductOrder cancelled"
        })

      updated_process_status =
        process_status
        |> Diffo.Provider.ProcessStatus.update!(%{parameterized_message: parameterized_message})

      assert updated_process_status.parameterized_message == parameterized_message
    end

    test "update code to nil - failure" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      process_status =
        Diffo.Provider.ProcessStatus.create!(%{
          instance_id: instance.id,
          code: "NBNACC-1003",
          severity: :WARN,
          message: "nbnProductOrder cancelled"
        })

      {:error, _error} = process_status |> Diffo.Provider.ProcessStatus.update(%{code: nil})
    end

    test "update severity to nil - failure" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      process_status =
        Diffo.Provider.ProcessStatus.create!(%{
          instance_id: instance.id,
          code: "NBNACC-1003",
          severity: :WARN,
          message: "nbnProductOrder cancelled"
        })

      {:error, _error} = process_status |> Diffo.Provider.ProcessStatus.update(%{severity: nil})
    end

    test "update message to nil - failure" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      process_status =
        Diffo.Provider.ProcessStatus.create!(%{
          instance_id: instance.id,
          code: "NBNACC-1003",
          severity: :WARN,
          message: "nbnProductOrder cancelled"
        })

      {:error, _error} = process_status |> Diffo.Provider.ProcessStatus.update(%{message: nil})
    end

    test "update parameterized message to nil - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})
      parameterized_message = %{reason: "cancelled due to force majeure"}

      process_status =
        Diffo.Provider.ProcessStatus.create!(%{
          instance_id: instance.id,
          code: "NBNACC-1003",
          severity: :WARN,
          message: "nbnProductOrder cancelled",
          parameterized_message: parameterized_message
        })

      updated_process_status =
        process_status |> Diffo.Provider.ProcessStatus.update!(%{parameterized_message: nil})

      assert updated_process_status.parameterized_message == nil
    end
  end

  describe "Diffo.Provider.ProcessStatus encode" do
    test "encode json - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      process_status =
        Diffo.Provider.ProcessStatus.create!(%{
          instance_id: instance.id,
          code: "NBNACC-1003",
          severity: :WARN,
          message: "nbnProductOrder cancelled"
        })

      encoding = Jason.encode!(process_status) |> Diffo.Util.summarise_dates()

      assert encoding ==
               "{\"code\":\"NBNACC-1003\",\"severity\":\"WARN\",\"message\":\"nbnProductOrder cancelled\",\"timeStamp\":\"now\"}"
    end

    test "encode json with parameterized message - success" do
      parameterized_message = %{reason: "cancelled due to force majeure"}
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      process_status =
        Diffo.Provider.ProcessStatus.create!(%{
          instance_id: instance.id,
          code: "NBNACC-1003",
          severity: :WARN,
          message: "nbnProductOrder cancelled",
          parameterized_message: parameterized_message
        })

      encoding = Jason.encode!(process_status) |> Diffo.Util.summarise_dates()

      assert encoding ==
               "{\"code\":\"NBNACC-1003\",\"severity\":\"WARN\",\"message\":\"nbnProductOrder cancelled\",\"parameterizedMessage\":{\"reason\":\"cancelled due to force majeure\"},\"timeStamp\":\"now\"}"
    end
  end

  [:code, :severity, :message, :parameterized_message, :timestamp]

  describe "Diffo.Provider outstanding ProcessStatus" do
    use Outstand
    @now DateTime.utc_now()
    @parameterized_message %{reason: "cancelled due to force majeure"}
    @code_only %Diffo.Provider.ProcessStatus{code: "NBNACC-1003"}
    @severity_only %Diffo.Provider.ProcessStatus{severity: "WARN"}
    @message_only %Diffo.Provider.ProcessStatus{message: "nbnProductOrder cancelled"}
    @parameterized_message_only %Diffo.Provider.ProcessStatus{
      parameterized_message: @parameterized_message
    }
    @timestamp_only %Diffo.Provider.ProcessStatus{timestamp: @now}
    @specific_process_status %Diffo.Provider.ProcessStatus{
      code: "NBNACC-1003",
      severity: "WARN",
      message: "nbnProductOrder cancelled",
      parameterized_message: @parameterized_message,
      timestamp: @now
    }
    @generic_process_status %Diffo.Provider.ProcessStatus{
      code: &__MODULE__.generic_process_status_code/1,
      severity: nil,
      message: nil,
      parameterized_message: nil,
      timestamp: nil
    }
    @actual_process_status %Diffo.Provider.ProcessStatus{
      code: "NBNACC-1003",
      severity: "WARN",
      message: "nbnProductOrder cancelled",
      parameterized_message: @parameterized_message,
      timestamp: @now
    }

    gen_nothing_outstanding_test(
      "specific nothing outstanding",
      @specific_process_status,
      @actual_process_status
    )

    gen_result_outstanding_test(
      "specific process_status result",
      @specific_process_status,
      nil,
      @specific_process_status
    )

    gen_result_outstanding_test(
      "specific code result",
      @specific_process_status,
      Map.delete(@actual_process_status, :code),
      @code_only
    )

    gen_result_outstanding_test(
      "specific severity result",
      @specific_process_status,
      Map.delete(@actual_process_status, :severity),
      @severity_only
    )

    gen_result_outstanding_test(
      "specific message result",
      @specific_process_status,
      Map.delete(@actual_process_status, :message),
      @message_only
    )

    gen_result_outstanding_test(
      "specific parameterized_message result",
      @specific_process_status,
      Map.delete(@actual_process_status, :parameterized_message),
      @parameterized_message_only
    )

    gen_result_outstanding_test(
      "specific timestamp result",
      @specific_process_status,
      Map.delete(@actual_process_status, :timestamp),
      @timestamp_only
    )

    gen_nothing_outstanding_test(
      "generic nothing outstanding",
      @generic_process_status,
      @actual_process_status
    )
  end

  describe "Diffo.Provider delete ProcessStatus" do
    test "delete process_status with related instance - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      process_status =
        Diffo.Provider.ProcessStatus.create!(%{
          instance_id: instance.id,
          code: "NBNACC-1003",
          severity: :WARN,
          message: "nbnProductOrder cancelled"
        })

      :ok = Diffo.Provider.delete_process_status(process_status)
      {:error, _error} = Diffo.Provider.get_process_status_by_id(process_status.id)
    end
  end

  def generic_process_status_code(actual) do
    cond do
      actual == nil ->
        :generic_process_status_code

      Regex.match?(~r/NBNACC-\d{4}/, String.Chars.to_string(actual)) ->
        nil

      true ->
        :generic_process_status_code
    end
  end
end

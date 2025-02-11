defmodule Diffo.Provider.ProcessStatus do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference
  Copyright Matt Beanland beanland@live.com.au

  ProcessStatus - Embedded Ash Resource for a TMF ProcessStatus
  """
  use Ash.Resource, otp_app: :diffo, domain: Diffo.Provider, data_layer: :embedded, embed_nil_values?: false, extensions: [AshJason.Resource]

  jason do
    pick [:code, :severity, :message, :parameterized_message, :timestamp]
    customize fn result, record ->
      result
      |> Diffo.Util.suppress(:message)
      |> Diffo.Util.suppress(:parameterized_message)
      |> Diffo.Util.set(:timestamp, Diffo.Util.to_iso8601(record.timestamp))
    end
    rename parameterized_message: :parameterizedMessage
  end

  code_interface do
    define :create
    define :update
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      description "creates a process status"
      accept [:code, :severity, :message, :parameterized_message]
      change set_attribute :timestamp, &DateTime.utc_now/0
    end

    update :update do
       description "updates a process status, and updates the timestamp"
       change set_attribute :timestamp, &DateTime.utc_now/0
    end
  end

  attributes do
    attribute :code, :string do
      description "the code of this process status, this is a mandatory value"
      allow_nil? false
      public? true
    end

    attribute :severity, :atom do
      description "the severity of this process status, this is a mandatory value"
      allow_nil? false
      public? true
    end

    attribute :message, :string do
      description "the message of this process status, this is a mandatory value"
      allow_nil? false
      public? true
    end

    attribute :parameterized_message, :term do
      description "the parameterized message of this process status, this is an optional value"
      allow_nil? true
      public? true
    end

    attribute :timestamp, :utc_datetime_usec do
      description "the timestamp of this process status, timestamp is create or last update"
      allow_nil? false
    end
  end

  preparations do
    prepare build(sort: [timestamp: :desc])
  end

  @doc """
  Compares two process status, by timestamp
  ## Examples
    iex> Diffo.Provider.ProcessStatus.compare(%{timestamp: "a"}, %{timestamp: "a"})
    :eq
    iex> Diffo.Provider.ProcessStatus.compare(%{timestamp: "b"}, %{timestamp: "a"})
    :gt
    iex> Diffo.Provider.ProcessStatus.compare(%{timestamp: "a"}, %{timestamp: "b"})
    :lt

  """
  def compare(%{timestamp: timestamp0}, %{timestamp: timestamp1}), do: Diffo.Util.compare(timestamp0, timestamp1)
end

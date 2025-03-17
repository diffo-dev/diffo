defmodule Diffo.Uuid do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference
  Copyright Matt Beanland beanland@live.com.au

  Uuid - validate and/or create uuids
  """

    @doc """
    Generates a uuid4
    """
    def uuid4() do
      UUID.uuid4()
    end

    @doc """
    Ensures the supplied uuid is valid uuid4, if not creates one.
    ## Examples
      iex> validated = Diffo.Uuid.uuid4("4cc5b107-0ff3-4bda-80e1-e4264cbaf868")
      iex> validated
      "4cc5b107-0ff3-4bda-80e1-e4264cbaf868"

      iex> generated = Diffo.Uuid.uuid4(nil)
      iex> valid = Diffo.Uuid.uuid4?(generated)
      iex> valid
      true

    """
    def uuid4(id) do
      info = UUID.info(id)
      case info do
        {:ok, result} ->
        if result[:version] != 4 do
          UUID.uuid4()
        else
          id
        end
      {:error, _message} ->
        UUID.uuid4()
      end
    end

    @doc """
    Tests whether the uuid is uuid4.
    ## Examples
      iex> Diffo.Uuid.uuid4?("746e465b-3969-460a-980f-af69c9ab248a")
      true

      iex> Diffo.Uuid.uuid4?("9a4cdc44-ca5a-11ef-9cd2-0242ac120002")
      false

      iex> Diffo.Uuid.uuid4?(nil)
      false

    """
    def uuid4?(id) when not is_nil(id) do
      info = UUID.info(id)
      case info do
        {:ok, result} ->
          if result[:version] == 4 do
            true
          else
            false
          end
        {:error, _message} ->
          false
      end
    end

    def uuid4?(nil) do
      false
    end

    @doc """
    Tests whether the uuid is uuid4 or nil.
    ## Examples
      iex> Diffo.Uuid.uuid4_or_nil?("746e465b-3969-460a-980f-af69c9ab248a")
      true

      iex> Diffo.Uuid.uuid4_or_nil?("9a4cdc44-ca5a-11ef-9cd2-0242ac120002")
      false

      iex> Diffo.Uuid.uuid4_or_nil?(nil)
      true

    """
    def uuid4_or_nil?(id) when not is_nil(id) do
      uuid4?(id)
    end

    def uuid4_or_nil?(nil) do
      true
    end

    @doc """
    Returns trailing uuid4 if valid, or nil.
    ## Examples
      iex> Diffo.Uuid.trailing_uuid4("serviceInventoryManagement/v4/service/accessEvc/d2566874-d5ee-400b-9983-10d63ec52f32")
      "d2566874-d5ee-400b-9983-10d63ec52f32"

      iex> Diffo.Uuid.trailing_uuid4("serviceInventoryManagement/v4/service/accessEvc/d2566874-d5ee-400b-9983")
      nil

      iex> Diffo.Uuid.trailing_uuid4("d2566874-d5ee-400b-9983-10d63ec52f32")
      "d2566874-d5ee-400b-9983-10d63ec52f32"

      iex> Diffo.Uuid.trailing_uuid4(nil)
      nil

    """
    def trailing_uuid4(input) when is_bitstring(input) do
      uuid = String.slice(input, -36, 36)
      if (uuid4?(uuid)) do
        uuid
      else
        nil
      end
    end

    def trailing_uuid4(_) do
      nil
    end

    @doc """
    Callback function for outstanding to expect uuid4.
    ## Examples

      iex> Diffo.Uuid.expect_uuid4("d2566874-d5ee-400b-9983-10d63ec52f32")
      nil

      iex> Diffo.Uuid.expect_uuid4("serviceInventoryManagement/v4/service/accessEvc/d2566874-d5ee-400b-9983-10d63ec52f32")
      :uuid4

      iex> Diffo.Uuid.expect_uuid4(nil)
      :uuid4

    """
    def expect_uuid4(actual) do
      if uuid4?(actual) do
        nil
      else
        :uuid4
      end
    end

    @doc """
    Callback function for outstanding to expect trailing uuid4.
    ## Examples
      iex> Diffo.Uuid.expect_trailing_uuid4("serviceInventoryManagement/v4/service/accessEvc/d2566874-d5ee-400b-9983-10d63ec52f32")
      nil

      iex> Diffo.Uuid.expect_trailing_uuid4("serviceInventoryManagement/v4/service/accessEvc/d2566874-d5ee-400b-9983")
      :trailing_uuid4

      iex> Diffo.Uuid.expect_trailing_uuid4("d2566874-d5ee-400b-9983-10d63ec52f32")
      nil

      iex> Diffo.Uuid.expect_trailing_uuid4(nil)
      :trailing_uuid4

    """
    def expect_trailing_uuid4(actual) do
      case trailing_uuid4(actual) do
        nil -> :trailing_uuid4
        _ -> nil
      end
    end

  end

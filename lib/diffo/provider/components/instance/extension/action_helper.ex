# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.ActionHelper do
  @moduledoc false
  alias Diffo.Provider.Instance.Specification
  alias Diffo.Provider.Instance.Relationship
  alias Diffo.Provider.Instance.Feature
  alias Diffo.Provider.Instance.Characteristic
  alias Diffo.Provider.Instance.Place
  alias Diffo.Provider.Instance.Party

  @doc """
  build before_action helper, injects instance dsl configuration into the changeset
  """
  def build_before(changeset) do
    changeset
    |> Specification.set_specified_by_argument()
    |> Feature.set_features_argument()
    |> Characteristic.set_characteristics_argument()
    |> Party.validate_parties()
  end

  @doc """
  build after_action helper, relates TMF entities to the new instance
  """
  def build_after(changeset, result) do
    specified_by = Ash.Changeset.get_argument(changeset, :specified_by)
    result = %{result | specification_id: specified_by}

    with {:ok, _} <- Specification.relate_instance(result, changeset),
         {:ok, _} <- Relationship.relate_instance(result, changeset),
         {:ok, _} <- Feature.relate_instance(result, changeset),
         {:ok, _} <- Characteristic.relate_instance(result, changeset),
         {:ok, _} <- Place.relate_instance(result, changeset),
         {:ok, _} <- Party.relate_instance(result, changeset),
         do: Ash.load(result, [:specification, :characteristics, :features, :parties])
  end
end

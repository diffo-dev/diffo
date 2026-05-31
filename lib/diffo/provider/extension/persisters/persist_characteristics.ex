# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.Persisters.PersistCharacteristics do
  @moduledoc """
  Persists characteristic declarations and bakes `characteristics/0`.

  The `characteristics do` DSL section can hold multiple entity kinds — the
  regular `%Characteristic{}` declarations (`characteristic :name, Module`), and
  the inherited variants (`%InheritedCharacteristicDeclaration{}` /
  `%ReverseInheritedCharacteristicDeclaration{}`) which produce calculations
  rather than typed characteristic resources.

  `characteristics/0` bakes only the regular `%Characteristic{}` declarations,
  because consumers of the function (the `:build` action's typed-characteristic
  creation, the runtime characteristic lookup, etc.) expect every entry to
  carry `:name` and `:value_type`. The inherited variants are kept in DSL state
  for `TransformInheritedRefs` to read and become calculations; they don't
  surface through `characteristics/0`.
  """
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer
  alias Diffo.Provider.Extension.Characteristic

  @impl true
  def transform(dsl_state) do
    all_declarations = Transformer.get_entities(dsl_state, [:provider, :characteristics])

    # Only regular Characteristic entries flow into characteristics/0; the
    # inherited variants are read separately by TransformInheritedRefs.
    typed = Enum.filter(all_declarations, &is_struct(&1, Characteristic))
    escaped = Macro.escape(typed)
    dsl_state = Transformer.persist(dsl_state, :characteristics, typed)

    {:ok,
     Transformer.eval(
       dsl_state,
       [],
       quote do
         @doc false
         def characteristics, do: unquote(escaped)
       end
     )}
  end
end

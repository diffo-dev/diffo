# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs/contributors>
#
# SPDX-License-Identifier: MIT

use Outstand

defoutstanding expected :: Diffo.Type.Primitive, actual :: Any do
  # we return a map since Primitive doesn't allow type nil
  type_outstanding =
    case actual do
      %{type: type} -> Outstanding.outstanding(expected.type, type)
      nil -> expected.type
      # actual is wrong type entirely
      _ -> expected.type
    end

  value_outstanding =
    case actual do
      %{} ->
        Outstanding.outstanding(
          Diffo.Unwrap.unwrap(expected),
          Diffo.Unwrap.unwrap(actual)
        )

      _ ->
        Diffo.Unwrap.unwrap(expected)
    end

  case {type_outstanding, value_outstanding} do
    {nil, nil} -> nil
    {nil, _} -> %{value: value_outstanding}
    {_, nil} -> %{type: type_outstanding}
    {_, _} -> %{type: type_outstanding, value: value_outstanding}
  end
end

# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs/contributors>
#
# SPDX-License-Identifier: MIT

use Outstand

defoutstanding expected :: Diffo.Type.Dynamic, actual :: Any do
  type_outstanding =
    case actual do
      %{type: type} -> Outstanding.outstanding(expected.type, type)
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
    {nil, _} -> %Diffo.Type.Dynamic{type: nil, value: value_outstanding}
    {_, nil} -> %Diffo.Type.Dynamic{type: type_outstanding, value: nil}
    {_, _} -> %Diffo.Type.Dynamic{type: type_outstanding, value: value_outstanding}
  end
end

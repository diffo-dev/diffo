# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defprotocol Diffo.Unwrap do
  @moduledoc """
  `Diffo.Unwrap` is a protocol for extracting the underlying Elixir value from Diffo and Ash
  wrapper types. It is defined with `@fallback_to_any true`, so any value without an explicit
  implementation is returned unchanged.

  By convention, implementations are recursive — each one calls `Diffo.Unwrap.unwrap/1` on its
  inner value, so nested wrappers are fully peeled in a single call.

  Built-in implementations are provided for `Ash.Union`, `Ash.CiString`, `Ash.NotLoaded`,
  `Diffo.Type.Primitive`, `Diffo.Type.Dynamic`, and `List`.

  ## Examples

  Any plain Elixir value is returned as-is:

      iex> Diffo.Unwrap.unwrap(42)
      42

      iex> Diffo.Unwrap.unwrap("hello")
      "hello"

      iex> Diffo.Unwrap.unwrap(nil)
      nil

  A `Diffo.Type.Primitive` unwraps to the raw value:

      iex> Diffo.Type.Primitive.wrap("integer", 7) |> Diffo.Unwrap.unwrap()
      7

  An `Ash.Union` wrapping a `Diffo.Type.Primitive` unwraps recursively:

      iex> %Ash.Union{type: :integer, value: Diffo.Type.Primitive.wrap("integer", 7)}
      ...> |> Diffo.Unwrap.unwrap()
      7

  A list of wrapped values is unwrapped element-by-element:

      iex> [Diffo.Type.Primitive.wrap("integer", 1), Diffo.Type.Primitive.wrap("integer", 2)]
      ...> |> Diffo.Unwrap.unwrap()
      [1, 2]
  """
  @fallback_to_any true
  def unwrap(value)
end

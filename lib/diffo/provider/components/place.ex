# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Place do
  @moduledoc """
  Ash Resource for a TMF Place
  """
  use Ash.Resource, fragments: [Diffo.Provider.BasePlace], domain: Diffo.Provider

  resource do
    description "An Ash Resource for a TMF Place"
    plural_name :places
  end

  jason do
    pick [:id, :href, :name, :referred_type, :type]
    compact true
    rename referred_type: "@referredType", type: "@type"
  end

  outstanding do
    expect [:id, :name, :referred_type, :type]
  end
end

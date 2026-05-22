# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Characteristic.Extension do
  @moduledoc """
  Marker extension identifying a module as a valid characteristic resource.

  Also synthesises default `:create` and `:update` actions on
  `BaseCharacteristic`-derived resources from the resource's declared public
  attributes — `:create` accepts `[:name | <public_attrs>]` with
  `:instance_id` / `:feature_id` arguments and corresponding
  `manage_relationship` changes; `:update` accepts `<public_attrs>` only.
  Consumers may declare their own `:create` / `:update` actions to override
  the synthesised ones.
  """
  use Spark.Dsl.Extension,
    sections: [],
    transformers: [Diffo.Provider.Characteristic.Extension.Transformers.GenerateActions]
end

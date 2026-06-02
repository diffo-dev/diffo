# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.VerifyProviderDomainTest do
  @moduledoc false
  use ExUnit.Case, async: false
  @moduletag :domain_extended
  import ExUnit.CaptureIO
  alias Diffo.Test.Util

  describe "VerifyProviderDomain (#219)" do
    # A provider leaf whose domain does NOT compose Diffo.Provider.DomainFragment lacks the
    # :Provider label, so it can't be projected/resolved. Catch it at compile time instead
    # of failing silently at runtime.
    test "a provider leaf in a fragment-less domain warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "does not carry the :Provider Neo4j label",
        fn ->
          defmodule NoProviderDomain do
            use Ash.Domain, otp_app: :diffo, validate_config_inclusion?: false

            resources do
              allow_unregistered?(true)
            end
          end

          defmodule PlaceWithoutProvider do
            use Ash.Resource, fragments: [Diffo.Provider.BasePlace], domain: NoProviderDomain

            resource do
              description "place in a domain lacking Diffo.Provider.DomainFragment"
            end

            jason do
              pick [:id, :type]
              rename type: "@type"
            end

            outstanding do
              expect [:id, :type]
            end

            actions do
              create :build do
                accept [:id, :name]
                change set_attribute(:type, :GeographicSite)
              end
            end
          end
        end
      )
    end

    # The same leaf in a domain that DOES compose the fragment carries :Provider and
    # compiles cleanly — no projection footgun, no error.
    test "a provider leaf in a domain composing DomainFragment compiles without the error" do
      output =
        capture_io(:stderr, fn ->
          defmodule ProviderDomain do
            use Ash.Domain,
              otp_app: :diffo,
              validate_config_inclusion?: false,
              fragments: [Diffo.Provider.DomainFragment]

            resources do
              allow_unregistered?(true)
            end
          end

          defmodule PlaceWithProvider do
            use Ash.Resource, fragments: [Diffo.Provider.BasePlace], domain: ProviderDomain

            resource do
              description "place in a domain composing Diffo.Provider.DomainFragment"
            end

            jason do
              pick [:id, :type]
              rename type: "@type"
            end

            outstanding do
              expect [:id, :type]
            end

            actions do
              create :build do
                accept [:id, :name]
                change set_attribute(:type, :GeographicSite)
              end
            end
          end
        end)

      refute output =~ "does not carry the :Provider Neo4j label"
    end
  end
end

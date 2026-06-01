# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.RelationshipDslTest do
  @moduledoc false
  use ExUnit.Case, async: true
  @moduletag :domain_extended
  alias Diffo.Test.Util
  alias Diffo.Test.Instance.ShelfInstance
  alias Diffo.Test.Instance.CardInstance
  alias Diffo.Test.Parties
  alias Diffo.Provider.Extension.RelationshipStep
  alias Diffo.Provider.Instance.Relationship, as: RelStruct

  # ── module-level fixture for last-wins test ─────────────────────────────────

  defmodule LastWinsInstance do
    alias Diffo.Provider.BaseInstance
    use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

    resource do
      description "tests pipeline last-wins"
      plural_name :last_wins
    end

    provider do
      specification do
        id "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
        name "lastWins"
        type :resourceSpecification
      end

      relationships do
        source [:provides]
        source :all
      end
    end
  end

  # ── TransformRelationships — baked functions ────────────────────────────────

  describe "TransformRelationships — baked functions" do
    test "ShelfInstance has source :all declared" do
      assert ShelfInstance.permitted_source_roles() == :all
    end

    test "ShelfInstance has no target declaration — defaults to :none" do
      assert ShelfInstance.permitted_target_roles() == :none
    end

    test "CardInstance has target :all declared" do
      assert CardInstance.permitted_target_roles() == :all
    end

    test "CardInstance has no source declaration — defaults to :none" do
      assert CardInstance.permitted_source_roles() == :none
    end

    test "ShelfInstance.relationships/0 returns raw pipeline steps" do
      steps = ShelfInstance.relationships()
      assert is_list(steps)
      assert length(steps) == 1
      [step] = steps
      assert is_struct(step, RelationshipStep)
      assert step.direction == :source
      assert step.roles == :all
    end

    test "CardInstance.relationships/0 returns raw pipeline steps" do
      steps = CardInstance.relationships()
      assert is_list(steps)
      [step] = steps
      assert step.direction == :target
      assert step.roles == :all
    end

    test "pipeline last-wins — later source step overrides earlier" do
      # LastWinsInstance declares source [:provides] then source :all; :all wins
      assert LastWinsInstance.permitted_source_roles() == :all
      assert length(LastWinsInstance.relationships()) == 2
    end

    test "resource with no relationships section gets :none for both directions" do
      assert Diffo.Test.Instance.Broadband.permitted_source_roles() == :none
      assert Diffo.Test.Instance.Broadband.permitted_target_roles() == :none
    end
  end

  # ── VerifyRelationships — compile-time errors ───────────────────────────────

  describe "VerifyRelationships — compile-time errors" do
    test "non-atom in source roles list warns DslError" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        ~s(relationships: source role "not_an_atom" must be an atom),
        fn ->
          defmodule InvalidSourceRole do
            alias Diffo.Provider.BaseInstance
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with non-atom relationship role"
              plural_name :invalid_source_roles
            end

            provider do
              specification do
                id "b2c3d4e5-f6a7-8901-bcde-f12345678901"
                name "invalidRole"
                type :resourceSpecification
              end

              relationships do
                source ["not_an_atom"]
              end
            end
          end
        end
      )
    end

    test "empty list for source roles warns DslError" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "relationships: source roles must be :all, :none, or a non-empty list of atoms",
        fn ->
          defmodule EmptySourceRoles do
            alias Diffo.Provider.BaseInstance
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with empty source roles"
              plural_name :empty_source_roles
            end

            provider do
              specification do
                id "c3d4e5f6-a7b8-9012-cdef-123456789012"
                name "emptyRoles"
                type :resourceSpecification
              end

              relationships do
                source []
              end
            end
          end
        end
      )
    end

    test "non-atom in target roles list warns DslError — direction is reported" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        ~s(relationships: target role "not_an_atom" must be an atom),
        fn ->
          defmodule InvalidTargetRole do
            alias Diffo.Provider.BaseInstance
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with non-atom target relationship role"
              plural_name :invalid_target_roles
            end

            provider do
              specification do
                id "d4e5f6a7-b8c9-4012-9def-234567890123"
                name "invalidTargetRole"
                type :resourceSpecification
              end

              relationships do
                target ["not_an_atom"]
              end
            end
          end
        end
      )
    end

    test "non-list scalar roles warns DslError — e.g. the string \"all\" instead of the atom :all" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        ~s(relationships: source roles must be :all, :none, or a non-empty list of atoms, got: "all"),
        fn ->
          defmodule ScalarSourceRoles do
            alias Diffo.Provider.BaseInstance
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with a string instead of :all for source roles"
              plural_name :scalar_source_roles
            end

            provider do
              specification do
                id "e5f6a7b8-c9d0-4123-8ef0-345678901234"
                name "scalarSourceRoles"
                type :resourceSpecification
              end

              relationships do
                source "all"
              end
            end
          end
        end
      )
    end
  end

  # ── ValidateRelationshipPermitted — integration enforcement ─────────────────

  describe "ValidateRelationshipPermitted — integration enforcement" do
    setup do
      AshNeo4j.Sandbox.checkout()
      on_exit(&AshNeo4j.Sandbox.rollback/0)
    end

    test "relate action succeeds when source permits :all" do
      {:ok, shelf} = Parties.build_shelf_with_installer()
      {:ok, card} = Diffo.Test.Servo.build_card(%{})

      rel = %RelStruct{id: card.id, alias: :connects, type: :service, direction: :forward}

      result = Diffo.Test.Servo.relate_shelf(shelf, %{relationships: [rel]})
      assert {:ok, _} = result
    end

    test "relate action fails when source permits :none" do
      {:ok, card} = Diffo.Test.Servo.build_card(%{})
      {:ok, shelf} = Parties.build_shelf_with_installer()

      # CardInstance has source :none — relating as source should fail
      rel = %RelStruct{id: shelf.id, alias: :connects, type: :service, direction: :forward}

      result = Diffo.Test.Servo.relate_card(card, %{relationships: [rel]})

      assert {:error, error} = result
      assert Exception.message(error) =~ "not permitted as source"
    end

    test "relate action fails when target permits :none" do
      {:ok, shelf1} = Parties.build_shelf_with_installer()
      {:ok, shelf2} = Parties.build_shelf_with_installer()

      # ShelfInstance has target :none — being related to as target should fail
      rel = %RelStruct{id: shelf2.id, alias: :connects, type: :service, direction: :forward}

      result = Diffo.Test.Servo.relate_shelf(shelf1, %{relationships: [rel]})

      assert {:error, error} = result
      assert Exception.message(error) =~ "not permitted as target"
    end
  end
end

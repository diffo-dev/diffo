defmodule Diffo.Provider.NoteTest do
  @moduledoc false
  use ExUnit.Case

  setup_all do
    AshNeo4j.BoltxHelper.start()
  end

  setup do
    on_exit(fn ->
      AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  describe "Diffo.Provider read Notes" do
    test "list notes - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      t3_party =
        Diffo.Provider.create_party!(%{
          id: "T3_CONNECTIVITY",
          name: :entityId,
          href: "entity/internal/T3_CONNECTIVITY",
          referredType: :Entity
        })

      Diffo.Provider.create_note!(%{
        instance_id: instance.id,
        text: :"test service",
        note_id: "TST00000123456",
        author_id: t4_party.id
      })

      Diffo.Provider.create_note!(%{
        instance_id: instance.id,
        text: :"non commercial",
        note_id: "NOT010000873982",
        author_id: t3_party.id
      })

      notes = Diffo.Provider.list_notes!()
      assert length(notes) == 2
      # should be sorted by most recent first
      assert List.first(notes).author_id == "T3_CONNECTIVITY"
      assert List.last(notes).author_id == "T4_ACCESS"
    end

    test "find notes by note_id - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})
      instance2 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      t3_party =
        Diffo.Provider.create_party!(%{
          id: "T3_CONNECTIVITY",
          name: :entityId,
          href: "entity/internal/T3_CONNECTIVITY",
          referredType: :Entity
        })

      Diffo.Provider.create_note!(%{
        instance_id: instance1.id,
        text: :"test service",
        note_id: "TST00000123456",
        author_id: t4_party.id
      })

      Diffo.Provider.create_note!(%{
        instance_id: instance1.id,
        text: :"non commercial",
        note_id: "NOT010000873982",
        author_id: t3_party.id
      })

      Diffo.Provider.create_note!(%{
        instance_id: instance2.id,
        text: :"test service",
        note_id: "TST00000543543",
        author_id: t4_party.id
      })

      Diffo.Provider.create_note!(%{
        instance_id: instance2.id,
        text: :"non commercial",
        note_id: "NOT010000343853",
        author_id: t3_party.id
      })

      notes = Diffo.Provider.find_notes_by_note_id!("NOT") |> IO.inspect(label: :sorted_notes)
      assert length(notes) == 2
      # should be sorted by most recent first
      assert List.first(notes).note_id == "NOT010000343853"
      assert List.last(notes).note_id == "NOT010000873982"
    end

    test "list notes by related instance - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})
      instance2 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      t3_party =
        Diffo.Provider.create_party!(%{
          id: "T3_CONNECTIVITY",
          name: :entityId,
          href: "entity/internal/T3_CONNECTIVITY",
          referredType: :Entity
        })

      Diffo.Provider.create_note!(%{
        instance_id: instance1.id,
        text: :"test service",
        note_id: "TST00000123456",
        author_id: t4_party.id
      })

      Diffo.Provider.create_note!(%{
        instance_id: instance1.id,
        text: :"non commercial",
        note_id: "NOT010000873982",
        author_id: t3_party.id
      })

      Diffo.Provider.create_note!(%{
        instance_id: instance2.id,
        text: :"test service",
        note_id: "TST00000543543",
        author_id: t4_party.id
      })

      Diffo.Provider.create_note!(%{
        instance_id: instance2.id,
        text: :"non commercial",
        note_id: "NOT010000343853",
        author_id: t3_party.id
      })

      notes = Diffo.Provider.list_notes_by_instance_id!(instance1.id) |> IO.inspect()
      assert length(notes) == 2
      # should be sorted by descending timestamp
      assert List.first(notes).author_id == "T3_CONNECTIVITY"
      assert List.last(notes).author_id == "T4_ACCESS"
    end

    test "list notes by related author id - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})
      instance2 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      t3_party =
        Diffo.Provider.create_party!(%{
          id: "T3_CONNECTIVITY",
          name: :entityId,
          href: "entity/internal/T3_CONNECTIVITY",
          referredType: :Entity
        })

      Diffo.Provider.create_note!(%{
        instance_id: instance1.id,
        text: :"test service",
        note_id: "TST00000123456",
        author_id: t4_party.id
      })

      Diffo.Provider.create_note!(%{
        instance_id: instance1.id,
        text: :"non commercial",
        note_id: "NOT010000873982",
        author_id: t3_party.id
      })

      Diffo.Provider.create_note!(%{
        instance_id: instance2.id,
        text: :"test service",
        note_id: "TST00000543543",
        author_id: t4_party.id
      })

      Diffo.Provider.create_note!(%{
        instance_id: instance2.id,
        text: :"non commercial",
        note_id: "NOT010000343853",
        author_id: t3_party.id
      })

      notes = Diffo.Provider.list_notes_by_author_id!(t4_party.id)
      assert length(notes) == 2

      # notes are actually sorted by party_id, which is odd, as all the party_id's are the same! Should be sorted as notes!
      assert List.first(notes).note_id == "TST00000543543"
      assert List.last(notes).note_id == "TST00000123456"
    end
  end

  describe "Diffo.Provider create Notes" do
    test "create a note with no author  - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})
      note = Diffo.Provider.create_note!(%{instance_id: instance1.id, text: "123"})
      assert note.text == "123"
    end

    test "create a note with external id and author  - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      note =
        Diffo.Provider.create_note!(%{
          instance_id: instance1.id,
          text: :"test service",
          note_id: "TST000000123465",
          author_id: t4_party.id
        })

      assert note.note_id == "TST000000123465"
    end

    test "create - failure - must have one of text, external id, author_id" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})
      {:error, _error} = Diffo.Provider.create_note(%{instance_id: instance1.id})
    end

    test "create - failure - must have an instance" do
      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      {:error, _error} =
        Diffo.Provider.create_note(%{
          text: :"test service",
          note_id: "TST000000123465",
          author_id: t4_party.id
        })
    end

    test "create similar notes without note id on same instance - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      Diffo.Provider.create_note!(%{
        instance_id: instance1.id,
        text: :"test service",
        author_id: t4_party.id
      })

      Diffo.Provider.create_note!(%{
        instance_id: instance1.id,
        text: :"test service2",
        author_id: t4_party.id
      })
    end

    test "create duplicate notes without note id on same instance - failure" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      Diffo.Provider.create_note!(%{
        instance_id: instance1.id,
        text: :"test service",
        author_id: t4_party.id
      })

      {:error, _error} =
        Diffo.Provider.create_note(%{
          instance_id: instance1.id,
          text: :"test service",
          author_id: t4_party.id
        })
    end

    test "create similar notes with note id on same instance - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      Diffo.Provider.create_note!(%{
        instance_id: instance1.id,
        text: :"test service",
        note_id: "TST000000123465",
        author_id: t4_party.id
      })

      Diffo.Provider.create_note!(%{
        instance_id: instance1.id,
        text: :"test service",
        note_id: "TST000000123466",
        author_id: t4_party.id
      })
    end

    test "create duplicate notes with note id on same instance - failure" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      Diffo.Provider.create_note!(%{
        instance_id: instance1.id,
        text: :"test service",
        note_id: "TST000000123465",
        author_id: t4_party.id
      })

      {:error, _error} =
        Diffo.Provider.create_note(%{
          instance_id: instance1.id,
          text: :"test service",
          note_id: "TST000000123465",
          author_id: t4_party.id
        })
    end
  end

  describe "Diffo.Provider update Notes" do
    test "update note_id to nil - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      note =
        Diffo.Provider.create_note!(%{
          instance_id: instance1.id,
          text: :"test service",
          note_id: "TST000000123465",
          author_id: t4_party.id
        })

      updated_note = note |> Diffo.Provider.update_note!(%{note_id: nil})
      assert updated_note.note_id == nil
    end

    test "update note_id - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      note =
        Diffo.Provider.create_note!(%{
          instance_id: instance1.id,
          text: :"test service",
          note_id: "TST000000123465",
          author_id: t4_party.id
        })

      updated_note = note |> Diffo.Provider.update_note!(%{note_id: "TST000000123456"})
      assert updated_note.note_id == "TST000000123456"
    end

    test "remove note author - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      note =
        Diffo.Provider.create_note!(%{
          instance_id: instance1.id,
          text: :"test service",
          note_id: "TST000000123465",
          author_id: t4_party.id
        })

      updated_note =
        note
        |> Diffo.Provider.update_note_author!(%{author_id: nil})
        |> IO.inspect(label: :updated_note)

      assert updated_note.author_id == nil
    end

    test "replace note author - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      t3_party =
        Diffo.Provider.create_party!(%{
          id: "T3_CONNECTIVITY",
          name: :entityId,
          href: "entity/internal/T3_CONNECTIVITY",
          referredType: :Entity
        })

      note =
        Diffo.Provider.create_note!(%{
          instance_id: instance1.id,
          text: :"test service",
          note_id: "TST000000123465",
          author_id: t4_party.id
        })

      updated_note = note |> Diffo.Provider.update_note_author!(%{author_id: t3_party.id})
      assert updated_note.author_id == "T3_CONNECTIVITY"
    end

    test "update author_id - failure - author doesn't exist" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      note =
        Diffo.Provider.create_note!(%{
          instance_id: instance1.id,
          text: :"test service",
          note_id: "TST00000123456",
          author_id: t4_party.id
        })

      {:error, _error} = note |> Diffo.Provider.update_note_author(%{author_id: "T4_VIRTUAL"})
    end

    test "update instance_id - failure" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})
      instance2 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      note =
        Diffo.Provider.create_note!(%{
          instance_id: instance1.id,
          text: :"test service",
          note_id: "TST000000123465",
          author_id: t4_party.id
        })

      {:error, _error} = note |> Diffo.Provider.update_note(%{instance_id: instance2.id})
    end

    test "update instance_id - failure - instance doesn't exist" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      note =
        Diffo.Provider.create_note!(%{
          instance_id: instance1.id,
          text: :"test service",
          note_id: "TST000000123456",
          author_id: t4_party.id
        })

      {:error, _error} =
        note |> Diffo.Provider.update_note(%{instance_id: "cae0467e-4801-431c-a303-c3c7d5d44a40"})
    end

    test "update - failure - must have one of text, external id, author_id" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      note =
        Diffo.Provider.create_note!(%{
          instance_id: instance1.id,
          text: :"test service",
          note_id: "TST000000123456"
        })

      {:error, _error} = note |> Diffo.Provider.update_note(%{text: nil, note_id: nil})
    end
  end

  describe "Diffo.Provider encode Notes" do
    test "encode json with author - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      note =
        Diffo.Provider.create_note!(%{
          instance_id: instance1.id,
          text: :"test service",
          note_id: "TST000000123456",
          author_id: t4_party.id
        })

      refreshed_note = Diffo.Provider.get_note_by_id!(note.id)
      encoding = Jason.encode!(refreshed_note) |> Diffo.Util.summarise_dates()

      assert encoding ==
               "{\"text\":\"test service\",\"id\":\"TST000000123456\",\"author\":\"T4_ACCESS\",\"date\":\"now\"}"
    end

    test "encode json no author - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      note =
        Diffo.Provider.create_note!(%{
          instance_id: instance1.id,
          text: :"test service",
          note_id: "TST000000123456"
        })

      refreshed_note = Diffo.Provider.get_note_by_id!(note.id)
      encoding = Jason.encode!(refreshed_note) |> Diffo.Util.summarise_dates()
      assert encoding == "{\"text\":\"test service\",\"id\":\"TST000000123456\",\"date\":\"now\"}"
    end
  end

  describe "Diffo.Provider outstanding Notes" do
    use Outstand
    @text_only %Diffo.Provider.Note{text: "test service"}
    @note_id_only %Diffo.Provider.Note{note_id: "TST000000123456"}
    @author_id_only %Diffo.Provider.Note{author_id: "T4_ACCESS"}
    @specific_note %Diffo.Provider.Note{
      text: "test service",
      note_id: "TST000000123456",
      author_id: "T4_ACCESS"
    }
    @generic_note %Diffo.Provider.Note{
      text: "test service",
      note_id: &Diffo.Provider.NoteTest.generic_note/1,
      author_id: nil
    }
    @actual_note %Diffo.Provider.Note{
      text: "test service",
      note_id: "TST000000123456",
      author_id: "T4_ACCESS"
    }

    gen_nothing_outstanding_test("specific nothing outstanding", @specific_note, @actual_note)
    gen_result_outstanding_test("specific note result", @specific_note, nil, @specific_note)

    gen_result_outstanding_test(
      "specific text result",
      @specific_note,
      Map.delete(@actual_note, :text),
      @text_only
    )

    gen_result_outstanding_test(
      "specific note_id result",
      @specific_note,
      Map.delete(@actual_note, :note_id),
      @note_id_only
    )

    gen_result_outstanding_test(
      "specific author_id result",
      @specific_note,
      Map.delete(@actual_note, :author_id),
      @author_id_only
    )

    gen_nothing_outstanding_test("generic nothing outstanding", @generic_note, @actual_note)
  end

  describe "Diffo.Provider delete Notes" do
    test "delete note with related instance - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      note =
        Diffo.Provider.create_note!(%{
          instance_id: instance.id,
          text: :"test service",
          note_id: "TST000000123456"
        })

      :ok = Diffo.Provider.delete_note(note)
      {:error, _error} = Diffo.Provider.get_note_by_id(note.id)
    end
  end

  def generic_note(actual) do
    cond do
      actual == nil ->
        :generic_note

      Regex.match?(~r/TST\d{12}/, String.Chars.to_string(actual)) ->
        nil

      true ->
        :generic_note
    end
  end
end


 defmodule Diffo.Provider.ReferenceTest do
  @moduledoc false
  use ExUnit.Case
  use Diffo.DataCase, async: true

  describe "Diffo.Provider.Reference encode" do
    test "encode json - success" do
      reference = %Diffo.Provider.Reference{id: "8bcfbf9a-34a5-427a-8eae-5c3812466432", href: "serviceInventoryManagement/v4/service/siteConnection/8bcfbf9a-34a5-427a-8eae-5c3812466432"}
      assert Jason.encode!(reference) == "{\"id\":\"8bcfbf9a-34a5-427a-8eae-5c3812466432\",\"href\":\"serviceInventoryManagement/v4/service/siteConnection/8bcfbf9a-34a5-427a-8eae-5c3812466432\"}"
    end

    use Outstand
    @id_and_href %Diffo.Provider.Reference{id: "8bcfbf9a-34a5-427a-8eae-5c3812466432", href: "serviceInventoryManagement/v4/service/siteConnection/8bcfbf9a-34a5-427a-8eae-5c3812466432"}
    @id_only %Diffo.Provider.Reference{id: "8bcfbf9a-34a5-427a-8eae-5c3812466432"}
    @href_only %Diffo.Provider.Reference{href: "serviceInventoryManagement/v4/service/siteConnection/8bcfbf9a-34a5-427a-8eae-5c3812466432"}
    @any_id_and_href %Diffo.Provider.Reference{id: &Outstand.any_bitstring/1, href: &Outstand.any_bitstring/1}
    @instance_id_and_href %Diffo.Provider.Instance{id: "8bcfbf9a-34a5-427a-8eae-5c3812466432", href: "serviceInventoryManagement/v4/service/siteConnection/8bcfbf9a-34a5-427a-8eae-5c3812466432", type: :service}

    gen_nothing_outstanding_test("specific nothing outstanding", @id_and_href, @id_and_href)
    gen_result_outstanding_test("specific id and href result", @id_and_href, nil, @id_and_href)
    gen_result_outstanding_test("specific id result", @id_and_href, @href_only, @id_only)
    gen_result_outstanding_test("specific href result", @id_and_href, @id_only, @href_only)

    gen_nothing_outstanding_test("any nothing outstanding", @any_id_and_href, @id_and_href)
    gen_result_outstanding_test("any id and href result", @any_id_and_href, nil, @any_id_and_href)
    gen_result_outstanding_test("any id result", @any_id_and_href, @href_only, %Diffo.Provider.Reference{id: :any_bitstring})
    gen_result_outstanding_test("any href result", @any_id_and_href, @id_only, %Diffo.Provider.Reference{href: :any_bitstring})

    gen_nothing_outstanding_test("realized by instance", @any_id_and_href, @instance_id_and_href)
  end
end

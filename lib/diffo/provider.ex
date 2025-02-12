defmodule Diffo.Provider do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference
  Copyright Matt Beanland beanland@live.com.au

  Provider - API endpoint
  """
  use Ash.Domain,
    otp_app: :diffo

  resources do
    resource Diffo.Provider.Specification do
      define :create_specification, action: :create
      define :get_specification_by_id, action: :read, get_by: :id
      define :get_latest_specification_by_name, action: :get_latest, args: [:query]
      define :list_specifications, action: :list
      define :find_specifications_by_name, action: :find_by_name, args: [:query]
      define :find_specifications_by_category, action: :find_by_category, args: [:query]
      define :describe_specification, action: :describe
      define :categorise_specification, action: :categorise
      define :next_minor_specification, action: :next_minor
      define :next_patch_specification, action: :next_patch
      define :delete_specification, action: :destroy
    end

    resource Diffo.Provider.Instance do
      define :create_instance, action: :create
      define :get_instance_by_id, action: :read, get_by: :id
      define :list_instances, action: :list
      define :find_instances_by_name, action: :find_by_name, args: [:query]
      define :find_instances_by_specification_id, action: :find_by_specification_id, args: [:query]
      define :name_instance, action: :name
      define :cancel_service, action: :cancel
      define :feasibilityCheck_service, action: :feasibilityCheck
      define :reserve_service, action: :reserve
      define :deactivate_service, action: :deactivate
      define :activate_service, action: :activate
      define :suspend_service, action: :suspend
      define :terminate_service, action: :terminate
      define :status_instance, action: :status
      define :specify_instance, action: :specify
      define :delete_instance, action: :destroy
    end

    resource Diffo.Provider.Relationship do
      define :create_relationship, action: :create
      define :get_relationship_by_id, action: :read, get_by: :id
      define :list_relationships, action: :list
      define :list_service_relationships_from, action: :list_service_relationships_from, args: [:instance_id]
      define :list_resource_relationships_from, action: :list_resource_relationships_from, args: [:instance_id]
      define :update_relationship, action: :update
      define :delete_relationship, action: :destroy
    end

    resource Diffo.Provider.Characteristic do
      define :create_characteristic, action: :create
      define :get_characteristic_by_id, action: :read, get_by: :id
      define :list_characteristics, action: :list
      define :list_characteristics_by_related_id, action: :list_characteristics_by_related_id, args: [:related_id, :type]
      define :update_characteristic, action: :update
      define :delete_characteristic, action: :destroy
    end

    resource Diffo.Provider.Feature do
      define :create_feature, action: :create
      define :get_feature_by_id, action: :read, get_by: :id
      define :list_features, action: :list
      define :list_features_by_related_id, action: :list_features_by_related_id, args: [:related_id]
      define :update_feature, action: :update
      define :delete_feature, action: :destroy
    end

    resource Diffo.Provider.Place do
      define :create_place, action: :create
      define :get_place_by_id, action: :read, get_by: :id
      define :list_places, action: :list
      define :find_places_by_name, action: :find_by_name, args: [:query]
      define :update_place, action: :update
      define :delete_place, action: :destroy
    end

    resource Diffo.Provider.PlaceRef do
      define :create_place_ref, action: :create
      define :get_place_ref_by_id, action: :read, get_by: :id
      define :list_place_refs, action: :list
      define :find_place_refs_by_place_id, action: :find_by_place_id, args: [:query]
      define :list_place_refs_by_place_id, action: :list_place_refs_by_place_id, args: [:place_id]
      define :list_place_refs_by_instance_id, action: :list_place_refs_by_instance_id, args: [:instance_id]
      define :update_place_ref, action: :update
      define :delete_place_ref, action: :destroy
    end

    resource Diffo.Provider.Party do
      define :create_party, action: :create
      define :get_party_by_id, action: :read, get_by: :id
      define :list_parties, action: :list
      define :find_parties_by_name, action: :find_by_name, args: [:query]
      define :update_party, action: :update
      define :delete_party, action: :destroy
    end

    resource Diffo.Provider.PartyRef do
      define :create_party_ref, action: :create
      define :get_party_ref_by_id, action: :read, get_by: :id
      define :list_party_refs, action: :list
      define :find_party_refs_by_party_id, action: :find_by_party_id, args: [:query]
      define :list_party_refs_by_party_id, action: :list_party_refs_by_party_id, args: [:party_id]
      define :list_party_refs_by_instance_id, action: :list_party_refs_by_instance_id, args: [:instance_id]
      define :update_party_ref, action: :update
      define :delete_party_ref, action: :destroy
    end

    resource Diffo.Provider.ExternalIdentifier do
      define :create_external_identifier, action: :create
      define :get_external_identifier_by_id, action: :read, get_by: :id
      define :list_external_identifiers, action: :list
      define :find_external_identifiers_by_external_id, action: :find_by_external_id, args: [:query]
      define :list_external_identifiers_by_instance_id, action: :list_external_identifiers_by_instance_id, args: [:instance_id]
      define :list_external_identifiers_by_owner_id, action: :list_external_identifiers_by_owner_id, args: [:owner_id]
      define :update_external_identifier, action: :update
      define :delete_external_identifier, action: :destroy
    end

    resource Diffo.Provider.ProcessStatus do
      define :create_process_status, action: :create
      define :get_process_status_by_id, action: :read, get_by: :id
      define :list_process_statuses_by_instance_id, action: :list_process_statuses_by_instance_id, args: [:instance_id]
      define :update_process_status, action: :update
      define :delete_process_status, action: :destroy
    end

    resource Diffo.Provider.Note do
      define :create_note, action: :create
      define :get_note_by_id, action: :read, get_by: :id
      define :list_notes, action: :list
      define :find_notes_by_note_id, action: :find_by_note_id, args: [:query]
      define :list_notes_by_instance_id, action: :list_notes_by_instance_id, args: [:instance_id]
      define :list_notes_by_author_id, action: :list_notes_by_author_id, args: [:author_id]
      define :update_note, action: :update
      define :delete_note, action: :destroy
    end
  end
end

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
      define :set_specification_service_state_transition_map, action: :set_service_state_transition_map
      define :delete_specification, action: :destroy
    end

    resource Diffo.Provider.Instance do
      define :create_instance, action: :create
      define :get_instance_by_id, action: :read, get_by: :id
      define :list_instances, action: :list
      define :find_instances_by_name, action: :find_by_name, args: [:query]
      define :find_instances_by_specification_id, action: :find_by_specification_id, args: [:query]
      define :name_instance, action: :name
      define :cancel_instance, action: :cancel
      define :activate_instance, action: :activate
      define :terminate_instance, action: :terminate
      define :transition_instance, action: :transition
      define :delete_instance, action: :destroy
    end

    resource Diffo.Provider.Relationship do
      define :create_relationship, action: :create
      define :get_relationship_by_id, action: :read, get_by: :id
      define :list_relationships, action: :list
      define :find_relationships_by_id, action: :find_by_id
      define :set_relationship_alias, action: :alias
      define :set_relationship_type, action: :type
      define :set_reverse_relationship_type, action: :reverse_type
      define :delete_relationship, action: :destroy
    end
  end
end

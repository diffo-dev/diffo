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
      define :get_specification_by_id, action: :get_by_id, get_by: :id
      define :get_latest_specification_by_name, action: :get_latest, args: [:query]
      define :list_specifications, action: :list
      define :find_specifications_by_name, action: :find_by_name, args: [:query]
      define :find_specifications_by_category, action: :find_by_category, args: [:query]
      define :describe_specification, action: :describe
      define :categorise_specification, action: :categorise
      define :next_minor_specification, action: :next_minor
      define :next_patch_specification, action: :next_patch
      define :set_specification_service_state_transition_map, action: :set_service_state_transition_map
    end

    resource Diffo.Provider.Instance do
      define :create_instance, action: :create
      define :get_instance_by_id, action: :read, get_by: :id
      define :find_instances_by_name, action: :find, args: [:query]
      define :list_instances_by_specification_id, action: :list, args: [:query]
      define :name_instance, action: :name
      define :cancel_instance, action: :cancel
      define :activate_instance, action: :activate
      define :terminate_instance, action: :terminate
      define :transition_instance, action: :transition
    end
  end
end

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
      define :get_latest_specification_by_name, action: :get_latest
      define :find_specifications_by_name, action: :find
      define :describe_specification, action: :describe
      define :next_minor_specification, action: :next_minor
      define :next_patch_specification, action: :next_patch
    end
  end
end

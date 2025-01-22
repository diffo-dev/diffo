defmodule Diffo.Provider do
  use Ash.Domain,
    otp_app: :diffo

  resources do
    resource Diffo.Provider.Specification do
      define :create_specification, action: :create
    end
  end
end

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

OpenPath::Application.routes.draw do
  namespace :financial do
    resources :clients, only: [:show] do
      get 'rollup/:partial', to: 'clients#rollup', as: :rollup
    end
  end
end

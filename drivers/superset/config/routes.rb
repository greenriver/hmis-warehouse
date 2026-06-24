###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

OpenPath::Application.routes.draw do
  namespace :superset do
    namespace :warehouse_reports do
      resources :reports, only: [:index]
    end
  end
end

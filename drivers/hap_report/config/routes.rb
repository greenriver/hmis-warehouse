###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :hap_report do
    namespace :warehouse_reports do
      resources :hap_reports do
        get :details, on: :member
      end
    end
  end
end

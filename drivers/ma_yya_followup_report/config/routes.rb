###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :ma_yya_followup_report do
    namespace :warehouse_reports do
      resources :youth_followup, only: [:index]
    end
  end
end

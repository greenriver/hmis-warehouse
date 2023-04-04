###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  namespace :health_ip_followup_report do
    namespace :warehouse_reports do
      resources :followup_reports, only: [:index]
    end
  end
end

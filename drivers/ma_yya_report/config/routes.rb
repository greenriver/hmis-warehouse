###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

Rails.application.routes.draw do
  namespace :ma_yya_report do
    namespace :warehouse_reports do
      resources :report, only: [:index]
    end
  end
end

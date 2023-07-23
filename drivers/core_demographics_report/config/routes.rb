###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

Rails.application.routes.draw do
  namespace :core_demographics_report do
    namespace :warehouse_reports do
      [:core, :demographic_summary].each do |report|
        resources report, only: [:index] do
          get :details, on: :collection
          post :render_detail_section, on: :collection
          get 'section/:partial', on: :collection, to: "#{report}#section", as: :section
          get :filters, on: :collection
          get :download, on: :collection
          post :render_section, on: :collection
        end
      end
    end
  end
end

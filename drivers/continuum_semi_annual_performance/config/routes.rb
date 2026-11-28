###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

OpenPath::Application.routes.draw do
  namespace :continuum_semi_annual_performance do
    namespace :warehouse_reports do
      [:mid_year_reports, :end_of_year_reports].each do |r|
        resources r, only: [:index, :create, :show, :destroy] do
          post :approval, on: :member
          post :reload_from_csv, on: :member
        end
      end
    end
  end
end

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddReportingProjectIdToCasOpportunityCategories < ActiveRecord::Migration[7.1]
  def change
    add_column :cas_analytics_opportunity_categories, :reporting_project_id, :bigint
  end
end

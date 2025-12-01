###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddSubstanceUseAndSupportiveServicesToScorecard < ActiveRecord::Migration[7.2]
  def change
    add_column :boston_project_scorecard_reports, :substance_use_treatment_service, :jsonb
    add_column :boston_project_scorecard_reports, :supportive_services, :boolean, default: false
  end
end

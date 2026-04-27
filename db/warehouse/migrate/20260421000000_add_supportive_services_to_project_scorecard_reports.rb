# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AddSupportiveServicesToProjectScorecardReports < ActiveRecord::Migration[7.2]
  def change
    add_column :project_scorecard_reports, :supportive_services, :boolean
  end
end

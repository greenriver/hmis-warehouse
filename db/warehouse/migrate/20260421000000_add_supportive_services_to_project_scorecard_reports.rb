###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddSupportiveServicesToProjectScorecardReports < ActiveRecord::Migration[7.2]
  def change
    add_column :project_scorecard_reports, :supportive_services, :boolean
  end
end

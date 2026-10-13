###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProjectScorecard::DocumentExports::ScorecardExport, type: :model do
  let(:report_class) { ProjectScorecard::Report }
  let(:report_definition_url) { 'project_scorecard/warehouse_reports/scorecards' }

  it_behaves_like 'a document export limited to visible reports' do
    let(:query_key) { 'report_id' }

    it 'authorizes a scorecard for a project the user is a contact on' do
      project = create(:hud_project)
      create(:grda_warehouse_contact_project, user: own_reports_user, entity: project)
      report = report_class.create!(user_id: all_reports_user.id, project_id: project.id)

      expect(export_for(own_reports_user, report.id).authorized?).to be(true)
    end
  end
end

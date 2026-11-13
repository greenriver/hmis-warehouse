###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# The RRH and PSH sections re-run the report's filter limited to RRH or PSH projects.
# Picking only other project types must leave those sections empty, not widen them to
# every RRH or PSH project the user can report on.
RSpec.describe PerformanceMetrics::Report, type: :model do
  include AccessControlSetup

  let(:user) { create(:acl_user) }
  let(:data_source) { create(:source_data_source) }
  let!(:es_project) do
    create(:hud_project, data_source: data_source, ProjectType: HudHelper.util.project_type_number_from_code(:es).first)
  end
  let!(:rrh_project) do
    create(:hud_project, data_source: data_source, ProjectType: HudHelper.util.project_type_number_from_code(:rrh).first)
  end
  let(:report) { described_class.new(user_id: user.id) }

  before do
    collection = create(:collection)
    collection.set_viewables(projects: [es_project.id, rrh_project.id])
    setup_access_control(user, create(:role, can_view_assigned_reports: true), collection)

    report.filter = Filters::FilterBase.new(user_id: user.id, project_ids: [es_project.id])
  end

  it 'reports no RRH projects when only an ES project is selected' do
    rrh_report = report.send(:run_rrh)

    expect(rrh_report.all_projects).to be false
    expect(rrh_report.housed_scope.where(project_id: rrh_project.id)).to be_empty
  end

  it 'reports all reportable RRH projects when no project is selected' do
    report.filter = Filters::FilterBase.new(user_id: user.id)

    expect(report.send(:run_rrh).all_projects).to be true
  end
end

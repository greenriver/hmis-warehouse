###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/hud_enrollment_builders'

RSpec.describe ContinuumSemiAnnualPerformance::Report, type: :model, exclude_fixpoints: true do
  include_context 'HUD enrollment builders'

  let(:es_project) { create_project(project_type: 0, coc_code: 'XX-500') }
  let(:rrh_project) { create_project(project_type: 13, coc_code: 'XX-500') }
  let(:collection) { create(:collection) }
  let(:user) do
    create(:acl_user).tap do |u|
      setup_access_control(u, create(:role, can_view_assigned_reports: true, can_view_projects: true), collection)
    end
  end
  let(:report) { ContinuumSemiAnnualPerformance::EndOfYearReport.new(user_id: user.id) }

  before do
    create(:lookup_coc, coc_code: 'XX-500')
    collection.set_viewables({ projects: [es_project.id, rrh_project.id] })
  end

  def filter_for(project)
    ContinuumSemiAnnualPerformance::Filter.new(
      user_id: user.id, start: Date.new(2026, 1, 1), end: Date.new(2026, 12, 31),
      coc_codes: ['XX-500'], project_type_codes: [], project_ids: [project.id], enforce_one_year_range: false
    )
  end

  it 'drops the memoized project selection when the filter is reassigned' do
    report.filter = filter_for(es_project)
    expect(report.selected_project_ids).to eq([es_project.id])

    report.filter = filter_for(rrh_project)

    expect(report.selected_project_ids).to eq([rrh_project.id])
  end

  it 'is not left showing completed when a re-run fails' do
    report.filter = filter_for(es_project)
    report.save!
    report.complete
    GrdaWarehouse::Lookups::CocCode.where(coc_code: 'XX-500').find_each { |coc| coc.update!(active: false) }
    report.reload

    freeze_time do
      expect { report.run_and_save! }.to raise_error(ContinuumSemiAnnualPerformance::SubReportRunner::CocUnavailable)

      report.reload
      expect(report.completed_at).to be_nil
      expect(report.failed_at).to eq(Time.current)
    end
  end
end

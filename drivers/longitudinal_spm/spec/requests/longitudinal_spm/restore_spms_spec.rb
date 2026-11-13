###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Longitudinal SPM restore_spms', type: :request do
  include AccessControlSetup

  let(:user) { create(:acl_user) }
  let(:collection) { create(:collection) }

  before { GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions }

  let(:report_definition) do
    GrdaWarehouse::WarehouseReports::ReportDefinition.
      find_by!(url: 'longitudinal_spm/warehouse_reports/reports')
  end

  def sign_in_with(role, grant_report: true)
    collection.set_viewables(reports: [report_definition.id]) if grant_report
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  let!(:report) { LongitudinalSpm::Report.create!(user_id: user.id) }

  let!(:hud_spm) do
    HudReports::ReportInstance.create!(
      report_name: HudSpmReport.current_generator.title,
      question_names: ['Measure 1'],
      user_id: user.id,
      state: 'Completed',
      completed_at: Time.current,
      archival_metadata: {
        'archived_at' => 3.days.ago.iso8601,
        'expected_files' => ['report_cells_csv'],
        'purged_at' => 2.days.ago.iso8601,
      },
    )
  end

  let!(:spm) do
    LongitudinalSpm::Spm.create!(
      report_id: report.id,
      spm_id: hud_spm.id,
      start_date: '2023-01-01',
      end_date: '2023-12-31',
    )
  end

  let(:restore_path) { restore_spms_longitudinal_spm_warehouse_reports_report_path(report) }

  before { sign_in_with(create(:role, name: 'owner_role', can_view_all_reports: true, can_view_assigned_reports: true)) }

  it 'enqueues one restore job' do
    expect { post restore_path }.
      to have_enqueued_job(LongitudinalSpm::RestoreSpmsJob).with(report_id: report.id).once
  end

  it 'redirects back to the report' do
    post restore_path

    expect(response).to redirect_to(longitudinal_spm_warehouse_reports_report_path(report))
  end

  it 'enqueues nothing when a restore is already in flight' do
    hud_spm.begin_restore!

    expect { post restore_path }.not_to have_enqueued_job(LongitudinalSpm::RestoreSpmsJob)
  end

  it 'enqueues nothing when no backing SPM is purged' do
    hud_spm.remove_archival_metadata('purged_at')

    expect { post restore_path }.not_to have_enqueued_job(LongitudinalSpm::RestoreSpmsJob)
  end

  it 'restores for a user with no HUD report permission' do
    expect(user.can_view_hud_reports?).to eq(false)
    expect { post restore_path }.to have_enqueued_job(LongitudinalSpm::RestoreSpmsJob)
  end

  describe 'when the report is not visible to the user' do
    let(:other_user) { create(:acl_user) }

    before do
      collection.set_viewables(reports: [report_definition.id])
      setup_access_control(other_user, create(:role, name: 'limited_role', can_view_assigned_reports: true), collection)
      sign_in(other_user) # replaces the session established in the outer before block
    end

    it 'does not find the report' do
      post restore_path

      expect(response).to have_http_status(:not_found)
    end

    it 'enqueues nothing' do
      expect { post restore_path }.not_to have_enqueued_job(LongitudinalSpm::RestoreSpmsJob)
    end
  end
end

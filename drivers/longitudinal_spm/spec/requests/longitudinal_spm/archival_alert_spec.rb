###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Longitudinal SPM archival alert', type: :request do
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

  let(:show_path) { longitudinal_spm_warehouse_reports_report_path(report) }

  before { sign_in_with(create(:role, name: 'owner_role', can_view_all_reports: true, can_view_assigned_reports: true)) }

  context 'when purged and idle' do
    before { hud_spm.update_archival_metadata('purged_at', Time.current.iso8601) }

    it 'renders the warning, the restore button, and hides the charts' do
      get show_path

      expect(response.body).to include('One or more of the underlying SPM reports has been archived')
      expect(response.body).to include('Restore Archived SPM Data')
      expect(response.body).not_to include('Restoring the archived SPM reports')
      # `id='spm_...'` is only emitted by the chart div in show.haml's
      # `- unless @report.purged_spms.any?` block; its absence pins that guard.
      expect(response.body).not_to include("id='spm_")
    end
  end

  context 'when restoring' do
    before do
      # purged_at must predate restore_started_at by more than a second: both are
      # truncated to seconds by iso8601, and restoring? requires a strict >.
      hud_spm.update_archival_metadata('purged_at', 1.minute.ago.iso8601)
      hud_spm.begin_restore!
    end

    it 'renders the restoring message, hides the restore button, and registers the poller' do
      get show_path

      expect(response.body).to include('Restoring the archived SPM reports')
      expect(response.body).not_to include('Restore Archived SPM Data')
      expect(response.body).to include("data-poll-replace-url-value='#{running_longitudinal_spm_warehouse_reports_report_path(report)}'")
      expect(response.body).to include("data-poll-replace-active-value='true'")
      expect(response.body).not_to include('setInterval')
    end
  end

  context 'when the last restore attempt failed' do
    before do
      hud_spm.update_archival_metadata('purged_at', 1.minute.ago.iso8601)
      hud_spm.fail_restore!('universe_members_csv is not attached')
    end

    it 'renders a generic failure notice and the restore button, never the raw error' do
      get show_path

      expect(response.body).to include('The last restore attempt did not finish')
      expect(response.body).not_to include('universe_members_csv is not attached')
      expect(response.body).to include('Restore Archived SPM Data')
      expect(response.body).not_to include('Restoring the archived SPM reports')
      # Nothing to poll for: the controller connects inactive and never fires.
      expect(response.body).to include("data-poll-replace-active-value='false'")
    end
  end

  context 'when one backing SPM is restoring and another has a failed restore' do
    let!(:other_hud_spm) do
      HudReports::ReportInstance.create!(
        report_name: HudSpmReport.current_generator.title,
        question_names: ['Measure 1'],
        user_id: user.id,
        state: 'Completed',
        completed_at: Time.current,
        archival_metadata: {
          'archived_at' => 3.days.ago.iso8601,
          'expected_files' => ['report_cells_csv'],
        },
      )
    end

    let!(:other_spm) do
      LongitudinalSpm::Spm.create!(
        report_id: report.id,
        spm_id: other_hud_spm.id,
        start_date: '2022-01-01',
        end_date: '2022-12-31',
      )
    end

    before do
      hud_spm.update_archival_metadata('purged_at', 1.minute.ago.iso8601)
      hud_spm.begin_restore!

      other_hud_spm.update_archival_metadata('purged_at', 1.minute.ago.iso8601)
      other_hud_spm.fail_restore!('universe_members_csv is not attached')
    end

    it 'treats restoring as taking priority: no button, no error alert' do
      get show_path

      expect(response.body).to include('Restoring the archived SPM reports')
      expect(response.body).not_to include('Restore Archived SPM Data')
      expect(response.body).not_to include('The last restore attempt did not finish')
    end
  end

  context 'when nothing is purged' do
    before do
      # The chart section (guarded by `- unless @report.purged_spms.any?` in
      # show.haml, which this task must not touch) needs enough fake row/column
      # label metadata on each table to render without error.
      report.spm_measures.each_value do |tables|
        tables.each_key do |table|
          hud_spm.report_cells.create!(
            question: table,
            cell_name: nil,
            universe: false,
            metadata: { 'row_labels' => Array.new(20, 'label'), 'header_row' => Array.new(20, 'header') },
            summary: 0,
            status: 'Completed',
          )
        end
      end
    end

    it 'renders no archival alert' do
      get show_path

      expect(response.body).not_to include('longitudinal-spm-archival-alert')
    end
  end

  describe 'the poll endpoint' do
    let(:running_path) { running_longitudinal_spm_warehouse_reports_report_path(report) }
    let(:xhr_headers) { { 'X-Requested-With' => 'XMLHttpRequest' } }

    context 'while the backing SPMs are still purged' do
      before do
        hud_spm.update_archival_metadata('purged_at', 1.minute.ago.iso8601)
        hud_spm.begin_restore!
      end

      it 'returns the alert markup, with no inline script in the swapped-in HTML' do
        get running_path, headers: xhr_headers, xhr: true

        expect(response).to have_http_status(:success)
        expect(response.body).to include('longitudinal-spm-archival-alert')
        expect(response.body).to include('Restoring the archived SPM reports')
        # Swapped-in markup carries no script, so no CSP nonce has to be relayed
        # onto it; Stimulus picks up data-controller on the inserted node instead.
        expect(response.body).not_to include('<script')
        # The replacement re-declares the controller, which is how polling
        # continues after the swap.
        expect(response.body).to include("data-controller='poll-replace'")
        expect(response.body).to include("data-poll-replace-active-value='true'")
      end
    end

    context 'when the restore failed between polls' do
      before do
        hud_spm.update_archival_metadata('purged_at', 1.minute.ago.iso8601)
        hud_spm.fail_restore!('universe_members_csv is not attached')
      end

      it 'marks the alert as no longer restoring so the poller stops' do
        get running_path, headers: xhr_headers, xhr: true

        expect(response).to have_http_status(:success)
        expect(response.body).to include("data-poll-replace-active-value='false'")
      end
    end

    context 'when nothing is purged any more' do
      it 'returns 204 so the page reloads and the charts render' do
        get running_path, headers: xhr_headers, xhr: true

        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_blank
      end
    end

    it 'does not serve a plain browser GET' do
      get running_path

      expect(response).to have_http_status(:bad_request)
    end
  end

  context 'when a stale restore_error predates the current purge' do
    before do
      # Simulate a failed restore recorded before the report was re-archived: the
      # failure timestamp predates purged_at, so it must not surface as a current
      # failure per the staleness gating on restore_failed?.
      hud_spm.update_archival_metadata('restore_failed_at', 2.days.ago.iso8601)
      hud_spm.update_archival_metadata('restore_error', 'universe_members_csv is not attached')
      hud_spm.update_archival_metadata('purged_at', 1.day.ago.iso8601)
    end

    it 'does not render the stale failure notice' do
      get show_path

      expect(response.body).not_to include('The last restore attempt did not finish')
      expect(response.body).to include('Restore Archived SPM Data')
    end
  end
end

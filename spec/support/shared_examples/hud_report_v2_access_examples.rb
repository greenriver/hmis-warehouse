###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# The including spec defines: definition_url, report_name, index_path, new_path, history_path,
# and report_path_for (a lambda from a run to its show path). It may override run_options and
# run_attributes. `except:` skips examples a bare factory run can't render for that driver:
# :show_run, :destroy_run, :history_links.
RSpec.shared_examples 'HUD report access' do |except: []|
  let(:user) { create(:acl_user) }
  let(:other_user) { create(:acl_user) }
  let(:run_options) { { 'start' => '2025-10-01', 'end' => '2026-09-30', 'project_ids' => [] } }
  let(:run_attributes) { {} }
  let!(:own_run) { create(:hud_reports_report_instance, user: user, report_name: report_name, options: run_options, **run_attributes) }
  let!(:other_run) { create(:hud_reports_report_instance, user: other_user, report_name: report_name, options: run_options, **run_attributes) }

  # Permission lookups are cached in Rails.cache, which outlives each example's transaction.
  before { Rails.cache.clear }

  def granted
    grant_hud_report(user, definition_url)
    sign_in(user)
  end

  def granted_all_runs
    grant_hud_report(user, definition_url, role: create(:role, can_view_assigned_reports: true, can_view_all_hud_reports: true))
    sign_in(user)
  end

  # can_view_any_reports? is true, so the missing definition is the only reason for a denial.
  def not_granted
    setup_access_control(user, create(:role, can_view_assigned_reports: true), create(:collection))
    sign_in(user)
  end

  it 'opens the index, new, and history pages when the definition is granted' do
    granted
    [index_path, new_path, history_path].each do |path|
      get path
      expect(response).to have_http_status(:ok), path
    end
    unless except.include?(:history_links)
      expect(response.body).to include(report_path_for.call(own_run))
      expect(response.body).not_to include(report_path_for.call(other_run))
    end
  end

  it 'redirects every page with the not-authorized alert when the definition is not granted' do
    not_granted
    [index_path, new_path, history_path, report_path_for.call(own_run)].each do |path|
      get path
      expect(response).to redirect_to(warehouse_reports_path), path
      expect(flash[:alert]).to eq('Sorry you are not authorized to do that.')
    end
  end

  unless except.include?(:show_run)
    it "shows the user's own run and 404s another user's run" do
      granted
      get report_path_for.call(own_run)
      expect(response).to have_http_status(:ok)
      get report_path_for.call(other_run)
      expect(response).to have_http_status(:not_found)
    end

    it "shows another user's run with can_view_all_hud_reports" do
      granted_all_runs
      get report_path_for.call(other_run)
      expect(response).to have_http_status(:ok)
    end
  end

  unless except.include?(:destroy_run)
    it "deletes the user's own run" do
      granted
      delete report_path_for.call(own_run)
      expect(HudReports::ReportInstance.where(id: own_run.id)).to be_empty
    end
  end

  it "keeps another user's run and 404s the delete" do
    granted
    delete report_path_for.call(other_run)
    expect(response).to have_http_status(:not_found)
    expect(HudReports::ReportInstance.where(id: other_run.id).count).to eq(1)
  end

  it 'keeps the run when the definition is not granted' do
    not_granted
    delete report_path_for.call(own_run)
    expect(response).to redirect_to(warehouse_reports_path)
    expect(HudReports::ReportInstance.where(id: own_run.id).count).to eq(1)
  end
end

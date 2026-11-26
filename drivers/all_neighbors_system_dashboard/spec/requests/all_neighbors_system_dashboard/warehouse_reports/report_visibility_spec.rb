###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AllNeighborsSystemDashboard::WarehouseReports::Reports visibility', type: :request do
  let(:report_class) { AllNeighborsSystemDashboard::Report }
  let(:report_definition_url) { 'all_neighbors_system_dashboard/warehouse_reports/reports' }
  let(:report_path) { ->(report) { all_neighbors_system_dashboard_warehouse_reports_report_path(report) } }

  it_behaves_like 'report member actions limited to visible reports'

  describe 'publishing in sandbox mode' do
    include_context 'report visibility users'

    let(:owner) { user_with_role(can_view_assigned_reports: true, can_publish_reports: true) }
    let(:report) { report_class.create!(user_id: owner.id, **report_attributes) }
    let(:referer) { report_path.call(report) }
    let(:alert) { 'Public report publishing is disabled in sandbox mode' }

    before { sign_in(owner) }

    it 'refuses to queue publishing and enqueues no job' do
      with_sandbox_mode do
        expect do
          patch report_path.call(report),
                params: { public_report: { published_url: report.generate_publish_url } },
                headers: { 'HTTP_REFERER' => referer }
        end.not_to change(Delayed::Job, :count)
      end

      expect(response).to redirect_to(referer)
      expect(flash[:alert]).to eq(alert)
    end

    it 'refuses to unpublish and leaves the published copy untouched' do
      published_report = report.published_reports.create!(user_id: owner.id, path: report.path, published_url: 'https://example.test/report', state: :published)

      with_sandbox_mode do
        patch report_path.call(report),
              params: { public_report: { unpublish: report.generate_publish_url } },
              headers: { 'HTTP_REFERER' => referer }
      end

      expect(response).to redirect_to(referer)
      expect(flash[:alert]).to eq(alert)
      expect(published_report.reload.attributes.values_at('published_url', 'state')).to eq(['https://example.test/report', 'published'])
    end
  end
end

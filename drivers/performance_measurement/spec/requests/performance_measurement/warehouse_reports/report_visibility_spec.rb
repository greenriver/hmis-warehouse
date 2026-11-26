###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PerformanceMeasurement::WarehouseReports::Reports visibility', type: :request do
  let(:report_class) { PerformanceMeasurement::Report }
  let(:report_definition_url) { 'performance_measurement/warehouse_reports/reports' }
  let(:report_path) { ->(report) { performance_measurement_warehouse_reports_report_path(report) } }

  it_behaves_like 'report member actions limited to visible reports' do
    let(:report_attributes) { { goal_configuration: create(:performance_measurement_goal) } }
  end

  describe 'drilldowns' do
    include_context 'report visibility users'

    let(:report_attributes) { { goal_configuration: create(:performance_measurement_goal) } }

    before { sign_in(own_reports_user) }

    it 'returns not found for details on a report run by another user' do
      get performance_measurement_warehouse_reports_report_details_path(others_report, key: 'served_client_count')

      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found for project clients on a report run by another user' do
      get performance_measurement_warehouse_reports_report_clients_path(others_report, key: 'served_client_count', project_id: 1)

      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found for provider comparisons on a report run by another user' do
      get provider_comparisons_performance_measurement_warehouse_reports_report_path(others_report)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'publishing in sandbox mode' do
    include_context 'report visibility users'

    let(:report_attributes) { { goal_configuration: create(:performance_measurement_goal) } }

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
  end
end

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Legacy warehouse report visibility', type: :request do
  # Minimum parameters each report's index and show views need to render.
  report_parameters = {
    'chronic' => { filter: {} },
    'hud_chronics' => { filter: {} },
    'disabilities' => { filter: { start: '2024-01-01', end: '2024-12-31', sub_population: 'clients', disabilities: ['6'], project_types: ['1'] } },
    'active_veterans' => { range: {} },
  }

  {
    'chronic' => [GrdaWarehouse::WarehouseReports::ChronicReport, :warehouse_reports_chronic_path, :warehouse_reports_chronic_index_path],
    'hud_chronics' => [GrdaWarehouse::WarehouseReports::HudChronicReport, :warehouse_reports_hud_chronic_path, :warehouse_reports_hud_chronics_path],
    'disabilities' => [GrdaWarehouse::WarehouseReports::EnrolledDisabledReport, :warehouse_reports_disability_path, :warehouse_reports_disabilities_path],
    'active_veterans' => [GrdaWarehouse::WarehouseReports::ActiveVeteransReport, :warehouse_reports_active_veteran_path, :warehouse_reports_active_veterans_path],
  }.each do |slug, (klass, member_helper, index_helper)|
    describe slug do
      let(:report_class) { klass }
      let(:report_definition_url) { "warehouse_reports/#{slug}" }
      let(:report_path) { ->(report) { public_send(member_helper, report) } }

      it_behaves_like 'report member actions limited to visible reports' do
        let(:report_attributes) { { parameters: report_parameters.fetch(slug) } }
      end

      describe 'index' do
        include_context 'report visibility users'

        let(:report_attributes) { { parameters: report_parameters.fetch(slug) } }

        before { sign_in(own_reports_user) }

        it "lists the user's own report and not one run by another user" do
          get public_send(index_helper)

          expect(response.body).to include(public_send(member_helper, own_report))
          expect(response.body).not_to include(public_send(member_helper, others_report))
        end
      end
    end
  end
end

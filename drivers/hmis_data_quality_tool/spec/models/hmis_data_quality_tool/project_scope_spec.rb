###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HmisDataQualityTool::Report, type: :model do
  include_context 'DQ Tool test setup'

  describe 'with a posted project id the report owner cannot report on' do
    let!(:visible_project) { create_project(project_type: 0) }
    let!(:hidden_project) { create_project(project_type: 0) }
    # Replaces the shared context's all-data-sources collection with one holding only the visible project
    let(:data_sources_collection) do
      create(:collection).tap { |collection| collection.set_viewables({ projects: [visible_project.id] }) }
    end
    let!(:client) { create_client_with_warehouse_link }
    let!(:hidden_only_client) { create_client_with_warehouse_link }

    def create_inventory(project)
      create(
        :hud_inventory,
        ProjectID: project.ProjectID,
        project: project,
        data_source: data_source,
        CoCCode: 'MA-500',
        inventory_start_date: '2022-10-01'.to_date,
        inventory_end_date: '2023-09-30'.to_date,
        bed_inventory: 5,
      )
    end

    def client_item(client)
      HmisDataQualityTool::Client.find_by(report_id: @report.id, client_id: client.id)
    end

    before do
      create_inventory(visible_project)
      create_inventory(hidden_project)
      create_enrollment(client: client, project: visible_project, entry_date: '2022-11-01'.to_date, exit_date: '2022-12-15'.to_date)
      create_enrollment(client: client, project: hidden_project, entry_date: '2022-12-01'.to_date, exit_date: '2023-01-15'.to_date, household_id: 'other_household')
      create_enrollment(client: hidden_only_client, project: hidden_project, entry_date: '2022-12-01'.to_date, exit_date: '2023-01-15'.to_date, household_id: 'hidden_household')
    end

    context 'when the only posted project id is hidden' do
      before { @report = setup_report([hidden_project.id]) }

      it 'runs without hidden inventory or client items' do
        inventory_project_ids = HmisDataQualityTool::Inventory.where(report_id: @report.id).pluck(:project_id)

        expect(@report.completed_at).to be_present
        expect(inventory_project_ids).not_to include(hidden_project.id)
        expect(HmisDataQualityTool::Client.where(report_id: @report.id)).to be_empty
      end
    end

    context 'when a visible and a hidden project id are posted' do
      before { @report = setup_report([visible_project.id, hidden_project.id]) }

      it 'includes inventory only from the project the owner can report on' do
        inventory_project_ids = HmisDataQualityTool::Inventory.where(report_id: @report.id).pluck(:project_id)

        expect(inventory_project_ids).to contain_exactly(visible_project.id)
      end

      it 'leaves out clients enrolled only at the hidden project' do
        expect(client_item(client)).to be_present
        expect(client_item(hidden_only_client)).to be_nil
      end

      it 'does not treat the enrollment at the hidden project as part of the report' do
        expect_result(key: :overlapping_entry_exit_issues, invalid_count: 0)

        overlap_project_ids = client_item(client).overlapping_entry_exit_details.to_a.flatten.map { |enrollment| enrollment['project_id'] }
        expect(overlap_project_ids).not_to include(hidden_project.id)
      end
    end
  end
end

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Project data quality report chart keys', type: :model do
  let!(:data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hud_organization, data_source: data_source) }
  let!(:alpha) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectName: 'Hidden Alpha Shelter', confidential: true) }
  let!(:beta) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectName: 'Hidden Beta Shelter', confidential: true) }
  let!(:open_project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectName: 'Open Door Shelter') }
  let!(:project_group) { create(:project_group, projects: [alpha, beta, open_project]) }
  let!(:user) { create(:acl_user) }
  let(:placeholder) { GrdaWarehouse::Hud::Project.confidential_project_name }
  let(:expected_names) do
    {
      placeholder => alpha.id,
      "#{placeholder} (2)" => beta.id,
      'Open Door Shelter' => open_project.id,
    }
  end

  before do
    collection = create(:collection)
    collection.set_viewables({ projects: [alpha.id, beta.id, open_project.id] })
    setup_access_control(user, create(:role, can_view_projects: true), collection)
  end

  def build_rows(report)
    [alpha, beta, open_project].each do |p|
      Reporting::DataQualityReports::Project.create!(
        report_id: report.id,
        project_id: p.id,
        project_name: p.ProjectName,
        project_type: 1,
        nightly_client_census: {},
        nightly_household_census: {},
        calculated_at: Time.current,
      )
    end
    Reporting::DataQualityReports::ProjectGroup.create!(report_id: report.id, nightly_client_census: {}, nightly_household_census: {}, calculated_at: Time.current)
  end

  [:data_quality_report_version_four, :data_quality_report_version_five].each do |factory|
    context "on a #{factory}" do
      let!(:report) { create(factory, project: nil, project_group: project_group, completed_at: Time.current) }

      before { build_rows(report) }

      it 'gives each confidential project its own key in the census charts' do
        expect(report.bed_census_data(user)[:data].keys).to contain_exactly(*expected_names.keys, 'Total')
        expect(report.unit_census_data(user)[:data].keys).to contain_exactly(*expected_names.keys, 'Total')
      end

      it 'maps each chart key to its own project id for click-through' do
        [
          report.average_time_to_enter(user),
          report.average_time_to_exit(user),
          report.enrolled_length_of_stay(user),
          report.ph_destinations(user),
        ].each do |chart|
          expect(chart[:projects]).to eq(expected_names)
          expect(chart[:data].keys - ['Goal', 'Totals']).to match_array(expected_names.keys)
        end
      end
    end
  end
end

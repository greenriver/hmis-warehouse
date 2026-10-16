###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicReports::HomelessCountComparison, type: :model do
  let!(:user) { create(access_mode == :acl ? :acl_user : :user) }
  let!(:role) { create(:role, can_view_assigned_reports: true, can_view_project_related_filters: true) }

  let!(:data_source) { create(:grda_warehouse_data_source) }
  # `Project.viewable_by` excludes confidential projects via `non_confidential`, which inner-joins
  # the organization -- a project without an organization row is never viewable.
  let!(:organization) { create(:hud_organization, data_source: data_source) }
  let!(:project) { create(:hud_project, organization: organization, data_source: data_source, ProjectType: 1) }
  # Outside the user's access.
  let!(:other_project) { create(:hud_project, organization: organization, data_source: data_source, ProjectType: 1) }
  # Granted to the user, but the user can't report on confidential projects.
  let!(:confidential_project) { create(:hud_project, organization: organization, data_source: data_source, ProjectType: 1, confidential: true) }

  let(:report_start) { 2.months.ago.beginning_of_month.to_date }
  let(:report_end) { 1.month.ago.end_of_month.to_date }

  let!(:visible_client) { create(:grda_warehouse_hud_client) }
  let!(:other_project_client) { create(:grda_warehouse_hud_client) }
  let!(:confidential_client) { create(:grda_warehouse_hud_client) }

  # One open enrollment per client with service in both the prior and the current period.
  def build_entry(client, in_project)
    she = create(:she_entry, client: client, data_source: data_source, project: in_project, project_type: 1, first_date_in_program: report_start - 15.days, last_date_in_program: nil)
    [report_start - 15.days, report_start + 5.days].each do |service_date|
      create(:service_history_service, service_history_enrollment_id: she.id, client_id: client.id, date: service_date, record_type: 'service', project_type: 1)
    end
    she
  end
  let!(:visible_she) { build_entry(visible_client, project) }
  let!(:other_project_she) { build_entry(other_project_client, other_project) }
  let!(:confidential_she) { build_entry(confidential_client, confidential_project) }

  let(:selection) { {} }
  let(:report) do
    filter = ::Filters::FilterBase.new(user_id: user.id).update(start: report_start, end: report_end, enforce_one_year_range: false, **selection)
    described_class.create!(user_id: user.id, start_date: filter.start, end_date: filter.end, filter: filter.for_params)
  end

  def client_ids(scope_name)
    report.send(scope_name).distinct.pluck(:client_id)
  end

  before do
    Rails.cache.clear
    Collection.maintain_system_groups
    grant_project_access(user, role, [project, confidential_project], mode: access_mode)
  end

  [:acl, :legacy].each do |mode|
    context "with #{mode} access" do
      let(:access_mode) { mode }

      [:report_scope, :comparison_scope].each do |scope_name|
        describe "##{scope_name}" do
          context 'when no projects are selected' do
            it 'counts only enrollments in projects the user can view' do
              expect(client_ids(scope_name)).to contain_exactly(visible_client.id)
            end
          end

          context 'when a project outside the user\'s access is selected' do
            let(:selection) { { project_ids: [project.id, other_project.id] } }

            it 'excludes enrollments in that project' do
              expect(client_ids(scope_name)).to contain_exactly(visible_client.id)
            end
          end

          context 'when a confidential project is selected' do
            let(:selection) { { project_ids: [project.id, confidential_project.id] } }

            it 'excludes enrollments in that project' do
              expect(client_ids(scope_name)).to contain_exactly(visible_client.id)
            end
          end

          context 'when an organization is selected' do
            let!(:other_organization) { create(:hud_organization, data_source: data_source) }
            # Viewable, but in an unselected organization.
            let!(:other_organization_project) { create(:hud_project, organization: other_organization, data_source: data_source, ProjectType: 1) }
            let!(:other_organization_client) { create(:grda_warehouse_hud_client) }
            let!(:other_organization_she) { build_entry(other_organization_client, other_organization_project) }
            let(:selection) { { organization_ids: [organization.id] } }

            before { grant_project_access(user, role, [other_organization_project], mode: access_mode) }

            it 'counts only viewable, non-confidential enrollments in that organization' do
              expect(client_ids(scope_name)).to contain_exactly(visible_client.id)
            end
          end

          context 'when only unauthorized projects are selected' do
            let(:selection) { { project_ids: [other_project.id] } }

            it 'counts nothing' do
              expect(client_ids(scope_name)).to be_empty
            end
          end
        end
      end

      describe '#run_and_save!' do
        it 'compares both periods over the same projects' do
          report.run_and_save!

          expect(JSON.parse(report.reload.precalculated_data)).to include('count' => 0, 'change_direction' => 'no-change')
        end
      end
    end
  end
end

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForOrganizations do
  include_context 'filter criteria setup'

  let(:organization_ids) { [organization.id] }
  let(:filter) { ::Filters::FilterBase.new(user_id: user.id, organization_ids: organization_ids) }
  let(:criteria) { described_class.new(input: filter, config: config) }

  # Create additional organizations
  let!(:organization2) { create(:hud_organization, data_source_id: data_source.id) }
  let!(:organization3) { create(:hud_organization, data_source_id: data_source.id, confidential: true) } # Restricted org

  # Create projects for each organization
  let!(:project2) { create_project(organization_id: organization2.organization_id) }
  let!(:project3) { create_project(organization_id: organization3.organization_id) }

  # Create enrollments in different organizations via their projects
  let!(:enrollments) do
    [
      # Enrollment in the main organization's project
      create_enrollment_for_client(
        create(:hud_client),
        organization_id: organization.organization_id,
        project_id: project.project_id,
      ),

      # Enrollment in the second organization's project
      create_enrollment_for_client(
        create(:hud_client),
        organization_id: organization2.organization_id,
        project_id: project2.project_id,
      ),

      # Enrollment in the restricted organization's project
      create_enrollment_for_client(
        create(:hud_client),
        organization_id: organization3.organization_id,
        project_id: project3.project_id,
      ),
    ]
  end

  it_behaves_like 'a criteria that applies conditionally', :organization_ids, [1]

  describe '#apply' do
    it 'filters enrollments by the selected organization' do
      result = criteria.apply(scope)
      expect(result.pluck(:id)).to contain_exactly(enrollments[0].id)
    end

    context 'with different organization selection' do
      let(:organization_ids) { [organization2.id] }

      it 'returns enrollments from the selected organization' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[1].id)
      end
    end

    context 'when the user can only view some of the selected organizations' do
      let(:filter) { ::Filters::FilterBase.new(user_id: limited_user.id, organization_ids: [organization.id, organization2.id]) }

      [:acl, :legacy].each do |mode|
        context "with #{mode} access" do
          let(:limited_user) { create(mode == :acl ? :acl_user : :user) }

          before do
            Rails.cache.clear
            grant_project_access(limited_user, role, [project], mode: mode)
          end

          it 'returns enrollments from the viewable organizations only' do
            expect(criteria.apply(scope).pluck(:id)).to contain_exactly(enrollments[0].id)
          end
        end
      end

      # Legacy access ignores the permission, so this is ACL only
      context 'when report access and project viewing come from different roles' do
        let(:limited_user) { create(:acl_user) }
        let(:report_only_role) { create(:role, can_view_project_related_filters: true, can_view_assigned_reports: true, can_view_projects: false) }
        let(:view_only_role) { create(:role, can_view_project_related_filters: true, can_view_assigned_reports: false, can_view_projects: true) }

        before do
          grant_project_access(limited_user, report_only_role, [project], mode: :acl)
          grant_project_access(limited_user, view_only_role, [project2], mode: :acl)
        end

        it 'returns enrollments from the organizations the user can report on' do
          expect(criteria.apply(scope).pluck(:id)).to contain_exactly(enrollments[0].id)
        end
      end
    end

    context 'with multiple organizations selected' do
      let(:organization_ids) { [organization.id, organization2.id] }

      it 'returns enrollments from any of the selected organizations' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[0].id, enrollments[1].id)
      end
    end
  end
end

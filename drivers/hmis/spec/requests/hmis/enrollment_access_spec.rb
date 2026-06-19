###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

# Tests Enrollment.access schema fields are wired up correctly.
# See hmis_enrollment_policy_spec.rb for full policy coverage.
RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }

  before(:each) { hmis_login(user) }

  describe 'enrollment access' do
    let(:access_query) do
      <<~GRAPHQL
        query EnrollmentAccess($id: ID!) {
          enrollment(id: $id) {
            id
            access {
              id
              canViewEnrollmentDetails
              canEditEnrollments
              canDeleteEnrollments
              canSplitHouseholds
              canAuditEnrollments
              canViewEnrollmentLocationMap
            }
          }
        }
      GRAPHQL
    end

    def expect_enrollment_access!(enrollment:, access:)
      response, result = post_graphql(id: enrollment.id.to_s) { access_query }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'enrollment', 'access')).to include(
        'id' => enrollment.id.to_s,
        **access.stringify_keys,
      )
    end

    let(:view_permissions) { [:can_view_enrollment_details, :can_view_project] }

    it 'resolves all access fields from the enrollment policy' do
      create_access_control(
        hmis_user,
        p1,
        with_permission: [
          :can_edit_enrollments,
          :can_delete_enrollments,
          :can_split_households,
          :can_audit_enrollments,
          :can_view_enrollment_location_map,
          *view_permissions,
        ],
      )

      expect_enrollment_access!(
        enrollment: e1,
        access: {
          canViewEnrollmentDetails: true,
          canEditEnrollments: true,
          canDeleteEnrollments: true,
          canSplitHouseholds: true,
          canAuditEnrollments: true,
          canViewEnrollmentLocationMap: true,
        },
      )
    end

    context 'with permissions only in a different data source' do
      let!(:other_data_source) { create :hmis_data_source }
      let!(:access_control) { create_access_control(hmis_user, p1, with_permission: view_permissions) }
      let!(:full_access_other_data_source) { create_access_control(hmis_user, other_data_source) }

      it 'returns false for all editable access fields' do
        expect_enrollment_access!(
          enrollment: e1,
          access: {
            canViewEnrollmentDetails: true,
            canEditEnrollments: false,
            canDeleteEnrollments: false,
            canSplitHouseholds: false,
            canAuditEnrollments: false,
            canViewEnrollmentLocationMap: false,
          },
        )
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end

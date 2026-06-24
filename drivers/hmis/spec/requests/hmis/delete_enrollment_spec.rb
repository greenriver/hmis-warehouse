###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  let!(:access_control) { create_access_control(hmis_user, p1, with_permission: [:can_edit_enrollments, :can_delete_enrollments, :can_view_project, :can_view_enrollment_details, :can_view_clients]) }

  let(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:e1) { create :hmis_hud_wip_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1 }

  before(:each) do
    hmis_login(user)
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation DeleteEnrollment($input: DeleteEnrollmentInput!) {
        deleteEnrollment(input: $input) {
          enrollment {
            id
            entryDate
            relationshipToHoH
            client {
              id
            }
            intakeAssessment {
              id
            }
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  def perform_mutation(enrollment)
    response, result = post_graphql(input: { id: enrollment.id }) { mutation }
    expect(response.status).to eq 200
    enrollment = result.dig('data', 'deleteEnrollment', 'enrollment')
    errors = result.dig('data', 'deleteEnrollment', 'errors')
    [enrollment, errors]
  end

  context 'a completed, non-WIP enrollment with an intake assessment' do
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1 }
    let!(:a1) { create :hmis_custom_assessment, data_source: ds1, client: c1, enrollment: e1 }

    it 'should not allow deletion, even if user has permission to' do
      enrollment, errors = perform_mutation(e1)

      expect(enrollment).to be_present
      expect(errors).to contain_exactly(include('fullMessage' => 'Completed enrollments can not be deleted. Please exit the client instead.'))
      expect(e1.reload).not_to be_deleted
    end
  end

  context 'an incomplete (WIP) enrollment' do
    # User doesn't need can_delete_enrollments to delete WIP enrollments, just can_edit_enrollments (granted above)
    before { remove_permissions(access_control, :can_delete_enrollments) }

    it 'should be deleted successfully if user is authorized' do
      enrollment, errors = perform_mutation(e1)
      expect(enrollment).to be_present
      expect(errors).to be_empty
      expect(e1.reload).to be_deleted
    end

    it 'should throw gql error and not delete the enrollment if user is unauthorized' do
      remove_permissions(access_control, :can_edit_enrollments)
      expect_gql_error post_graphql(input: { id: e1.id }) { mutation }
      expect(e1.reload).not_to be_deleted
    end

    it 'should track metadata on versions' do
      versions = e1.versions
      expect do
        perform_mutation(e1)
      end.to change(versions, :count).by(1)
    end

    context 'with a WIP intake assessment' do
      let!(:a1) { create :hmis_custom_assessment, data_source: ds1, client: c1, enrollment: e1, data_collection_stage: 1 }

      it 'deletes the enrollment and WIP intake' do
        a1.save_in_progress
        enrollment, errors = perform_mutation(e1)
        expect(enrollment).to be_present
        expect(errors).to be_empty
        expect(e1.reload).to be_deleted
        expect(a1.reload).to be_deleted
      end
    end
  end

  context 'a completed enrollment without an intake assessment (edge case data quality issue)' do
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1 }

    it 'should be deleted successfully if user is authorized' do
      enrollment, errors = perform_mutation(e1)
      expect(enrollment).to be_present
      expect(errors).to be_empty
      expect(e1.reload).to be_deleted
    end

    it 'should throw gql error and not delete the enrollment if user is unauthorized' do
      remove_permissions(access_control, :can_delete_enrollments) # Even if they can edit, but not delete (unlike for WIP)
      expect_access_denied post_graphql(input: { id: e1.id }) { mutation }
      expect(e1.reload).not_to be_deleted
    end
  end

  context 'a multi-member household' do
    let!(:c2) { create :hmis_hud_client, data_source: ds1 }
    let!(:e2) { create :hmis_hud_wip_enrollment, data_source: ds1, project: p1, client: c2, relationship_to_ho_h: 2, household_id: e1.household_id }
    let!(:a2) { create :hmis_custom_assessment, data_source: ds1, client: c2, enrollment: e2, data_collection_stage: 2 }
    before do
      # HHM has WIP enrollment with in-progress intake assessment
      e2.save_in_progress
      a2.save_in_progress
    end

    it 'should delete the whole household when deleting the HoH' do
      enrollment, errors = perform_mutation(e1)
      expect(enrollment).to be_present
      expect(errors).to be_empty
      expect(e1.reload).to be_deleted
      expect(e2.reload).to be_deleted
      expect(a2.reload).to be_deleted
    end

    it 'should only delete one enrollment when deleting a non-HoH' do
      enrollment, errors = perform_mutation(e2)
      expect(enrollment).to be_present
      expect(errors).to be_empty
      expect(e1.reload).not_to be_deleted
      expect(e2.reload).to be_deleted # Only the HHM was deleted
      expect(a2.reload).to be_deleted # WIP intake was also deleted
    end

    context 'with wip HoH but non-wip HHM (edge case data quality issue)' do
      let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, relationship_to_ho_h: 2, household_id: e1.household_id }
      let!(:a2) { create :hmis_custom_assessment, data_source: ds1, client: c2, enrollment: e2, data_collection_stage: 2 }
      before do
        e2.save_not_in_progress
        remove_permissions(access_control, :can_delete_enrollments)
      end

      it 'should raise an error' do
        expect_access_denied post_graphql(input: { id: e1.id }) { mutation }
      end
    end
  end
end

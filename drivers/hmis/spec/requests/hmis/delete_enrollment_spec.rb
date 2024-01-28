###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  let!(:access_control) { create_access_control(hmis_user, p1, with_permission: [:can_view_project, :can_view_enrollment_details, :can_view_clients]) }
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c2) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c3) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1 }
  let!(:a1) { create :hmis_custom_assessment, data_source: ds1, user: u1, client: c1, enrollment: e1 }
  let!(:e2) { create :hmis_hud_wip_enrollment, data_source: ds1, project: p1, client: c2, relationship_to_ho_h: 2, household_id: e1.household_id }
  let!(:e3) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, relationship_to_ho_h: 1 }

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

  it 'should not allow deleting non-WIP enrollments, even if user has permission to' do
    # give user permission to edit/delete
    add_permissions(access_control, :can_edit_enrollments, :can_delete_enrollments)

    enrollment, errors = perform_mutation(e1)

    expect(enrollment).to be_present
    expect(errors).to contain_exactly(include('fullMessage' => 'Completed enrollments can not be deleted. Please exit the client instead.'))
    expect(e1.reload).not_to be_deleted
    expect(e2.reload).not_to be_deleted
  end

  it 'should allow deleting non-WIP enrollments if no intake assessment exists' do
    add_permissions(access_control, :can_edit_enrollments, :can_delete_enrollments)
    enrollment, errors = perform_mutation(e3)
    expect(enrollment).to be_present
    expect(errors).to be_empty
    expect(e1.reload).not_to be_deleted
    expect(e2.reload).not_to be_deleted
    expect(e3.reload).to be_deleted
  end

  it 'should allow deleting WIP enrollments' do
    add_permissions(access_control, :can_edit_enrollments)
    enrollment, errors = perform_mutation(e2)
    expect(enrollment).to be_present
    expect(errors).to be_empty
    expect(e1.reload).not_to be_deleted
    expect(e2.reload).to be_deleted
  end

  it 'should throw error if unauthorized (WIP and non-WIP, no access to edit enrollments)' do
    expect_gql_error post_graphql(input: { id: e1.id }) { mutation }
    expect_gql_error post_graphql(input: { id: e2.id }) { mutation }
    expect_gql_error post_graphql(input: { id: e3.id }) { mutation }
  end

  it 'tracks metadata on versions' do
    add_permissions(access_control, :can_edit_enrollments)
    versions = e2.versions.where(client_id: c2.id, enrollment_id: e2.id, project_id: p1.id)
    expect do
      perform_mutation(e2)
    end.to change(versions, :count).by(1)
  end
end

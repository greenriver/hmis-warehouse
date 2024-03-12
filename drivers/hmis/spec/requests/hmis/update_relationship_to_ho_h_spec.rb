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
  let!(:access_control) { create_access_control(hmis_user, p1) }
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c2) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c3) { create :hmis_hud_client, data_source: ds1, user: u1, first_name: 'Sally' }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1, household_id: '1', user: u1 }
  let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, relationship_to_ho_h: 2, household_id: '1', user: u1 }
  let!(:e3) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, relationship_to_ho_h: 3, household_id: '1', user: u1 }

  before(:each) do
    hmis_login(user)
  end

  let(:test_input) do
    {
      enrollment_id: e3.id,
      relationship_to_ho_h: Types::HmisSchema::Enums::Hud::RelationshipToHoH.enum_member_for_value(1).first,
      confirmed: true,
    }
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation UpdateRelationshipToHoH($input: UpdateRelationshipToHoHInput!) {
        updateRelationshipToHoH(input: $input) {
          enrollment {
            id
            relationshipToHoH
            client {
              id
            }
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  it 'should change hoh correctly' do
    response, result = post_graphql(input: test_input) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq(200), result.inspect
      enrollment = result.dig('data', 'updateRelationshipToHoH', 'enrollment')
      errors = result.dig('data', 'updateRelationshipToHoH', 'errors')
      expect(enrollment).to be_present
      expect(errors).to be_empty
      expect(Hmis::Hud::Enrollment.all).to contain_exactly(
        have_attributes(personal_id: c1.personal_id, relationship_to_ho_h: 99),
        have_attributes(personal_id: c2.personal_id, relationship_to_ho_h: 2),
        have_attributes(personal_id: c3.personal_id, relationship_to_ho_h: 1),
      )
    end
  end

  it 'should support fixing multiple-HoH household' do
    # e1 and e3 are both HoH
    e3.update(relationship_to_hoh: 1)
    # change HoH to e3
    response, result = post_graphql(input: test_input) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq(200), result.inspect
      enrollment = result.dig('data', 'updateRelationshipToHoH', 'enrollment')
      errors = result.dig('data', 'updateRelationshipToHoH', 'errors')
      expect(enrollment).to be_present
      expect(errors).to be_empty
      expect(e1.reload.relationship_to_hoh).to eq(99)
      expect(e3.reload.relationship_to_hoh).to eq(1)
    end
  end

  it 'should support fixing no-HoH household' do
    # no hh members are HoH
    e1.update(relationship_to_hoh: 2)
    # change HoH to e3
    response, result = post_graphql(input: test_input) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq(200), result.inspect
      enrollment = result.dig('data', 'updateRelationshipToHoH', 'enrollment')
      errors = result.dig('data', 'updateRelationshipToHoH', 'errors')
      expect(enrollment).to be_present
      expect(errors).to be_empty
      expect(e3.reload.relationship_to_hoh).to eq(1)
    end
  end

  it 'should not modify other records if non-HoH change' do
    input = test_input.merge(relationship_to_ho_h: Types::HmisSchema::Enums::Hud::RelationshipToHoH.enum_member_for_value(5).first)

    response, result = post_graphql(input: input) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      enrollment = result.dig('data', 'updateRelationshipToHoH', 'enrollment')
      errors = result.dig('data', 'updateRelationshipToHoH', 'errors')
      expect(enrollment).to be_present
      expect(errors).to be_empty
      expect(Hmis::Hud::Enrollment.all).to contain_exactly(
        have_attributes(personal_id: c1.personal_id, relationship_to_ho_h: 1),
        have_attributes(personal_id: c2.personal_id, relationship_to_ho_h: 2),
        have_attributes(personal_id: c3.personal_id, relationship_to_ho_h: 5),
      )
    end
  end

  it 'should warn if unconfirmed' do
    response, result = post_graphql(input: test_input.merge(confirmed: false)) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      enrollment = result.dig('data', 'updateRelationshipToHoH', 'enrollment')
      errors = result.dig('data', 'updateRelationshipToHoH', 'errors')
      expect(enrollment).to be nil
      expect(errors).to match([
                                a_hash_including('severity' => 'warning', 'fullMessage' => Mutations::UpdateRelationshipToHoH.change_hoh_message(c1, c3)),
                              ])
      e3.reload
      expect(e3.relationship_to_ho_h).not_to eq(1)
    end
  end

  it 'should warn if hoh is a child' do
    c3.update(dob: 13.years.ago)
    response, result = post_graphql(input: test_input.merge(confirmed: false)) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      enrollment = result.dig('data', 'updateRelationshipToHoH', 'enrollment')
      errors = result.dig('data', 'updateRelationshipToHoH', 'errors')
      expect(enrollment).to be nil
      expect(errors).to match([
                                a_hash_including('severity' => 'warning', 'fullMessage' => Mutations::UpdateRelationshipToHoH.change_hoh_message(c1, c3)),
                                a_hash_including('severity' => 'warning', 'fullMessage' => Mutations::UpdateRelationshipToHoH.child_hoh_message),
                              ])
      e3.reload
      expect(e3.relationship_to_ho_h).not_to eq(1)
    end
  end

  it 'should warn if WIP enrollment' do
    e3.save_in_progress!
    response, result = post_graphql(input: test_input.merge(confirmed: false)) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      enrollment = result.dig('data', 'updateRelationshipToHoH', 'enrollment')
      errors = result.dig('data', 'updateRelationshipToHoH', 'errors')
      expect(enrollment).to be nil
      expect(errors).to match([
                                a_hash_including('severity' => 'warning', 'fullMessage' => Mutations::UpdateRelationshipToHoH.change_hoh_message(c1, c3)),
                                a_hash_including('severity' => 'warning', 'fullMessage' => Mutations::UpdateRelationshipToHoH.incomplete_hoh_message),
                              ])
      e3.reload
      expect(e3.relationship_to_ho_h).not_to eq(1)
    end
  end

  it 'should warn if Exited enrollment' do
    create(:hmis_hud_exit, data_source: ds1, client: c3, enrollment: e3)
    response, result = post_graphql(input: test_input.merge(confirmed: false)) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      enrollment = result.dig('data', 'updateRelationshipToHoH', 'enrollment')
      errors = result.dig('data', 'updateRelationshipToHoH', 'errors')
      expect(enrollment).to be nil
      expect(errors).to match([
                                a_hash_including('severity' => 'warning', 'fullMessage' => Mutations::UpdateRelationshipToHoH.change_hoh_message(c1, c3)),
                                a_hash_including('severity' => 'warning', 'fullMessage' => Mutations::UpdateRelationshipToHoH.exited_hoh_message),
                              ])
      e3.reload
      expect(e3.relationship_to_ho_h).not_to eq(1)
    end
  end

  it 'should error if unauthorized' do
    remove_permissions(access_control, :can_edit_enrollments)
    expect_gql_error post_graphql(input: test_input) { mutation }, message: 'Access denied'
  end

  it 'should error if user does not have access to enrollment' do
    remove_permissions(access_control, :can_view_enrollment_details)
    remove_permissions(access_control, :can_edit_enrollments)
    expect_gql_error post_graphql(input: test_input) { mutation }, message: 'Not found'
  end

  it 'should error if enrollment does not exist' do
    expect_gql_error post_graphql(input: test_input.merge(enrollment_id: '0')) { mutation }, message: 'Not found'
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end

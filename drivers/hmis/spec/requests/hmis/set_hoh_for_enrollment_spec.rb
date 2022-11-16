require 'rails_helper'
require_relative 'login_and_permissions'
require_relative 'hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c2) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c3) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1, household_id: '1', user: u1 }
  let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, relationship_to_ho_h: 2, household_id: '1', user: u1 }
  let!(:e3) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, relationship_to_ho_h: 3, household_id: '1', user: u1 }

  before(:each) do
    hmis_login(user)
    assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation SetHoHForEnrollment($input: SetHoHForEnrollmentInput!) {
        setHoHForEnrollment(input: $input) {
          enrollment {
            id
            relationshipToHoH
            client {
              id
            }
          }
          errors {
            id
            attribute
            message
            fullMessage
            type
            options
            __typename
          }
        }
      }
    GRAPHQL
  end

  it 'should change hoh correctly' do
    response, result = post_graphql(input: { household_id: '1', client_id: c3.id }) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      enrollment = result.dig('data', 'setHoHForEnrollment', 'enrollment')
      errors = result.dig('data', 'setHoHForEnrollment', 'errors')
      expect(enrollment).to be_present
      expect(errors).to be_empty
      expect(Hmis::Hud::Enrollment.all).to contain_exactly(
        have_attributes(personal_id: c1.personal_id, relationship_to_ho_h: 99),
        have_attributes(personal_id: c2.personal_id, relationship_to_ho_h: 2),
        have_attributes(personal_id: c3.personal_id, relationship_to_ho_h: 1),
      )
    end
  end

  describe 'Validity tests' do
    [
      [
        'should emit error if client doesn\'t exist',
        ->(_client = nil) do
          {
            household_id: '1',
            client_id: '0',
          }
        end,
        {
          'message' => "No client with id '0'",
          'attribute' => 'clientId',
        },
      ],
      [
        'should emit error if household doesn\'t exist',
        ->(client = nil) do
          {
            household_id: '0',
            client_id: client&.id,
          }
        end,
        {
          'message' => "No enrollment for this client with household ID '0'",
          'attribute' => 'householdId',
        },
      ],
    ].each do |test_name, input_proc, error_attrs|
      it test_name do
        response, result = post_graphql(input: input_proc.call(c1)) { mutation }

        enrollment = result.dig('data', 'setHoHForEnrollment', 'enrollment')
        errors = result.dig('data', 'setHoHForEnrollment', 'errors')
        aggregate_failures 'checking response' do
          expect(response.status).to eq 200
          expect(enrollment).to be_nil
          expect(errors).to contain_exactly(
            include(**error_attrs),
          )
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end

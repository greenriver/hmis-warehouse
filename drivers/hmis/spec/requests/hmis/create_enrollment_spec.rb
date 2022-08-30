require 'rails_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  let(:user) { create :user }
  let(:ds1) { create :hmis_data_source }
  let(:o1) { create :hmis_hud_organization, data_source_id: ds1.id }
  let(:p1) { create :hmis_hud_project, data_source_id: ds1.id, OrganizationID: o1.OrganizationID }
  let(:c1) { create :hmis_hud_client, data_source: ds1 }
  let(:c2) { create :hmis_hud_client, data_source: ds1 }
  let(:c3) { create :hmis_hud_client, data_source: ds1 }
  let(:test_input) do
    {
      project_id: p1.id,
      start_date: Date.today.strftime('%Y-%m-%d'),
      household_members: [
        {
          id: c1.id,
          relationship_to_ho_h: Types::HmisSchema::Enums::RelationshipToHoH.enum_member_for_value(1).first,
        },
        {
          id: c2.id,
          relationship_to_ho_h: Types::HmisSchema::Enums::RelationshipToHoH.enum_member_for_value(2).first,
        },
        {
          id: c3.id,
          relationship_to_ho_h: Types::HmisSchema::Enums::RelationshipToHoH.enum_member_for_value(3).first,
        },
      ],
    }
  end

  describe 'enrollment creation tests' do
    before(:each) do
      user.add_viewable(ds1)
      post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
    end

    let(:mutation) do
      <<~GRAPHQL
        mutation CreateEnrollment($input: CreateEnrollmentValues!) {
          createEnrollment(input: { input: $input }) {
            enrollments {
              id
            }
            errors {
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

    it 'should create an enrollment successfully' do
      mutation_input = test_input

      response, result = post_graphql(input: mutation_input) { mutation }

      expect(response.status).to eq 200
      enrollments = result.dig('data', 'createEnrollment', 'enrollments')
      errors = result.dig('data', 'createEnrollment', 'errors')
      expect(enrollments).to be_present
      expect(errors).to be_empty
    end

    # it 'should throw errors if the client is invalid' do
    #   response, result = post_graphql(input: {}) { mutation }

    #   # client = result.dig('data', 'createClient', 'client')
    #   # errors = result.dig('data', 'createClient', 'errors')

    #   expect(response.status).to eq 200
    #   # expect(client).to be_nil
    #   expect(errors).to be_present
    # end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end

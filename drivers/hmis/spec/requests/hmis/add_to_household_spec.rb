###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c2) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c3) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:household_id) { Hmis::Hud::Base.generate_uuid }
  let!(:enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_hoh: 1, household_id: household_id }
  let!(:access_control) { create_access_control(hmis_user, p1) }

  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  describe 'AddToHousehold mutation' do
    before(:each) do
      hmis_login(user)
    end

    let(:test_input) do
      {
        project_id: p1.id,
        household_id: household_id,
        entry_date: Date.yesterday.strftime('%Y-%m-%d'),
        confirmed: true,
        client_id: c2.id,
        relationship_to_hoh: Types::HmisSchema::Enums::Hud::RelationshipToHoH.key_for(2),
      }
    end

    let(:mutation) do
      <<~GRAPHQL
        mutation AddToHousehold($input: AddToHouseholdInput!) {
          addToHousehold(input: $input) {
            household {
              id
              householdSize
              shortId
              householdClients {
                id
                relationshipToHoH
                enrollment {
                  id
                }
              }
            }
            #{error_fields}
          }
        }
      GRAPHQL
    end

    def perform_mutation(input)
      response, result = post_graphql(input: input) { mutation }
      expect(response.status).to eq 200
      household = result.dig('data', 'addToHousehold', 'household')
      errors = result.dig('data', 'addToHousehold', 'errors')
      [household, errors]
    end

    it 'should add members to an enrollment correctly' do
      household, errors = perform_mutation(test_input)
      expect(errors).to be_empty
      expect(household).to be_present
      expect(household['householdSize']).to eq(2)

      enrollments = Hmis::Hud::Enrollment.where(household_id: household_id)
      expect(enrollments.count).to eq(2)
      expect(enrollments.in_progress.count).to eq(1)
      expect(enrollments.in_progress.first).to have_attributes(
        enrollment_id: be_present,
        household_id: household_id,
        relationship_to_hoh: 2,
        personal_id: c2.personal_id,
        project_id: nil,
      )
    end

    it 'should add members to an in-progress enrollment correctly' do
      enrollment.save_in_progress

      household, errors = perform_mutation(test_input)
      expect(errors).to be_empty
      expect(household).to be_present
      expect(household['householdSize']).to eq(2)

      enrollments = Hmis::Hud::Enrollment.where(household_id: household_id)
      expect(enrollments.count).to eq(2)
      expect(enrollments.in_progress.count).to eq(2)

      # change enrollment back to non-WIP again
      enrollment.project = p1
      enrollment.save_not_in_progress
    end

    it 'should create a new household if household_id is omitted' do
      input = test_input.merge(household_id: nil, relationship_to_hoh: Types::HmisSchema::Enums::Hud::RelationshipToHoH.key_for(1))
      household, errors = perform_mutation(input)

      expect(errors).to be_empty
      expect(household).to be_present
      expect(household['householdSize']).to eq(1)
      enrollment_id = household['householdClients'][0]['enrollment']['id']
      enrollment = Hmis::Hud::Enrollment.find(enrollment_id)
      expect(enrollment).to have_attributes(
        enrollment_id: be_present,
        household_id: be_present,
        relationship_to_hoh: 1,
        personal_id: c2.personal_id,
        project_id: nil,
      )
      expect(enrollment.project).to eq(p1)
    end

    it 'should throw error if unauthorized' do
      remove_permissions(access_control, :can_edit_enrollments)
      expect { post_graphql(input: test_input) { mutation } }.to raise_error(HmisErrors::ApiError)
    end

    it 'should error if client is already in the household' do
      input = test_input.merge(client_id: c1.id)
      expect { post_graphql(input: input) { mutation } }.to raise_error(HmisErrors::ApiError)
    end

    it 'should error if household doesnt exist' do
      input = test_input.merge(household_id: 'notreal')
      expect { post_graphql(input: input) { mutation } }.to raise_error(HmisErrors::ApiError)
    end

    describe 'Validity tests' do
      [
        [
          'should return error if household already has a HoH',
          ->(input) { input.merge(relationship_to_hoh: Types::HmisSchema::Enums::Hud::RelationshipToHoH.key_for(1)) },
          {
            attribute: :relationshipToHoh,
            severity: :error,
            type: :invalid,
          },
        ],
        [
          'should return error if entry date is in the future',
          ->(input) { input.merge(entry_date: (Date.today + 1.week).strftime('%Y-%m-%d')) },
          {
            message: Hmis::Hud::Validators::BaseValidator.future_message,
            attribute: :entryDate,
            severity: :error,
            type: :out_of_range,
          },
        ],
      ].each do |test_name, input_proc, error_attrs|
        it test_name do
          input = input_proc.call(test_input)
          household, errors = perform_mutation(input)
          expect(household).to be_nil
          expect(errors).to contain_exactly(
            include(**error_attrs.transform_keys(&:to_s).transform_values(&:to_s)),
          )
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end

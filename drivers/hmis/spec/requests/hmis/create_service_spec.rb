###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'
  include_context 'hmis service setup'
  let!(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1, household_id: '1', user: u1 }

  let(:test_input) do
    {
      enrollment_id: e1.id,
      date_provided: Date.yesterday.strftime('%Y-%m-%d'),
      record_type: Types::HmisSchema::Enums::Hud::RecordType.enum_member_for_value(144).first,
      type_provided: Types::HmisSchema::Enums::ServiceTypeProvided.enum_member_for_value('144:3').first,
      sub_type_provided: Types::HmisSchema::Enums::ServiceSubTypeProvided.enum_member_for_value('144:3:1').first,
      other_type_provided: 'Other Type',
      moving_on_other_type: 'Moving On Other Type',
      fa_amount: 1.5,
      referral_outcome: Types::HmisSchema::Enums::Hud::PATHReferralOutcome.enum_member_for_value(1).first,
    }
  end

  before(:each) do
    hmis_login(user)
    assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation CreateService($input: ServiceInput!) {
        createService(input: { input: $input }) {
          service {
            #{scalar_fields(Types::HmisSchema::Service)}
            enrollment {
              id
            }
            client {
              id
            }
            user {
              id
            }
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  it 'should create a service successfully' do
    response, result = post_graphql(input: test_input) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      service = result.dig('data', 'createService', 'service')
      errors = result.dig('data', 'createService', 'errors')
      expect(service['id']).to be_present
      expect(service['id']).to eq(Hmis::Hud::HmisService.first.id.to_s)
      expect(errors).to be_empty
    end
  end

  it 'should throw errors if the service is invalid' do
    response, result = post_graphql(input: {}) { mutation }

    service = result.dig('data', 'createService', 'service')
    errors = result.dig('data', 'createService', 'errors')

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      expect(service).to be_nil
      expect(errors).to be_present
    end
  end

  describe 'Validity tests' do
    [
      [
        'should emit error if enrollment ID is not provided',
        ->(input) { input.except(:enrollment_id) },
        {
          fullMessage: 'Enrollment not found',
        },
      ],
      [
        'should emit error if enrollment does not exist',
        ->(input) { input.merge(enrollment_id: '0') },
        {
          fullMessage: 'Enrollment not found',
        },
      ],
      [
        'should emit error if type provided is not valid for the provided record type',
        ->(input) do
          input = input.merge(
            record_type: Types::HmisSchema::Enums::Hud::RecordType.enum_member_for_value(200).first,
            type_provided: Types::HmisSchema::Enums::ServiceTypeProvided.enum_member_for_value('144:3').first,
          )
          input[:sub_type_provided] = nil
          input
        end,
        {
          attribute: :typeProvided,
          type: :invalid,
          severity: :error,
        },
      ],
      [
        'should emit error if sub type provided provided when not record type 144',
        ->(input) do
          input.merge(
            record_type: Types::HmisSchema::Enums::Hud::RecordType.enum_member_for_value(141).first,
            type_provided: Types::HmisSchema::Enums::ServiceTypeProvided.enum_member_for_value('141:1').first,
          )
        end,
        {
          attribute: :subTypeProvided,
          type: :invalid,
          severity: :error,
        },
      ],
      [
        'should emit error if sub type provided provided when record type is 144 but type provided is not 3, 4 or 5',
        ->(input) do
          input.merge(
            record_type: Types::HmisSchema::Enums::Hud::RecordType.enum_member_for_value(144).first,
            type_provided: Types::HmisSchema::Enums::ServiceTypeProvided.enum_member_for_value('144:1').first,
          )
        end,
        {
          attribute: :subTypeProvided,
          type: :invalid,
          severity: :error,
        },
      ],
      [
        'should emit error if sub type provided provided does not match type provided',
        ->(input) do
          input.merge(
            record_type: Types::HmisSchema::Enums::Hud::RecordType.enum_member_for_value(144).first,
            type_provided: Types::HmisSchema::Enums::ServiceTypeProvided.enum_member_for_value('144:3').first,
            sub_type_provided: Types::HmisSchema::Enums::ServiceSubTypeProvided.enum_member_for_value('144:5:7').first,
          )
        end,
        {
          attribute: :subTypeProvided,
          type: :invalid,
          severity: :error,
        },
      ],
    ].each do |test_name, input_proc, *expected_errors|
      it test_name do
        input = input_proc.call(test_input)
        response, result = post_graphql(input: input) { mutation }
        errors = result.dig('data', 'createService', 'errors')
        aggregate_failures 'checking response' do
          expect(response.status).to eq 200
          expect(errors).to match(expected_errors.map do |h|
            a_hash_including(**h.transform_keys(&:to_s).transform_values(&:to_s))
          end)
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end

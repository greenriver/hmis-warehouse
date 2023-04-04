###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'
require_relative '../../support/hmis_service_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'
  include_context 'hmis service setup'
  let(:u2) do
    user2 = create(:user).tap { |u| u.add_viewable(ds1) }
    hmis_user2 = Hmis::User.find(user2.id)&.tap { |u| u.update(hmis_data_source_id: ds1.id) }
    Hmis::Hud::User.from_user(hmis_user2)
  end
  let!(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, client: c1, project: p1, user: u1 }
  let!(:hud_s1) { create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, date_updated: Date.today - 1.week, user: u2 }
  let(:s1) { Hmis::Hud::HmisService.find_by(owner: hud_s1) }

  let(:test_input) do
    {
      date_provided: Date.yesterday.strftime('%Y-%m-%d'),
      record_type: Types::HmisSchema::Enums::Hud::RecordType.enum_member_for_value(144).first,
      type_provided: Types::HmisSchema::Enums::ServiceTypeProvided.enum_member_for_value('144:3').first,
      sub_type_provided: Types::HmisSchema::Enums::ServiceSubTypeProvided.enum_member_for_value('144:3:1').first,
      other_type_provided: 'Other Type',
      moving_on_other_type: 'Moving On Other Type',
      'FAAmount' => 1.5,
      referral_outcome: Types::HmisSchema::Enums::Hud::PATHReferralOutcome.enum_member_for_value(1).first,
    }
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation UpdateService($id: ID!, $input: ServiceInput!) {
        updateService(input: { input: $input, id: $id }) {
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

  before(:each) do
    hmis_login(user)
    assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
  end

  it 'should update a service successfully' do
    prev_date_updated = s1.date_updated
    expect(s1.user_id).to eq(u2.user_id)

    response, result = post_graphql(input: test_input, id: s1.id) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      service = result.dig('data', 'updateService', 'service')
      errors = result.dig('data', 'updateService', 'errors')
      expect(s1.reload.date_updated > prev_date_updated).to eq(true)
      expect(s1.user_id).to eq(u1.user_id)
      expect(service).to include(
        'id' => s1.id.to_s,
        'dateProvided' => test_input[:date_provided],
        'recordType' => test_input[:record_type],
        'typeProvided' => test_input[:type_provided],
        'subTypeProvided' => test_input[:sub_type_provided],
        'otherTypeProvided' => test_input[:other_type_provided],
        'movingOnOtherType' => test_input[:moving_on_other_type],
        'FAAmount' => test_input['FAAmount'],
        'referralOutcome' => test_input[:referral_outcome],
      )
      expect(errors).to be_empty
    end
  end

  it 'should throw error if unauthorized' do
    remove_permissions(hmis_user, :can_edit_enrollments)
    response, result = post_graphql(input: test_input, id: s1.id) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      service = result.dig('data', 'updateService', 'service')
      errors = result.dig('data', 'updateService', 'errors')
      expect(errors).to be_present
      expect(errors).to contain_exactly(include('type' => 'not_allowed'))
      expect(service).to be_nil

      service = Hmis::Hud::Service.find(s1.owner.id)
      expect(service.record_type == s1.owner.record_type).to eq(true)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end

require 'rails_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  let!(:ds1) { create :hmis_data_source }
  let!(:user) { create(:user).tap { |u| u.add_viewable(ds1) } }
  let(:hmis_user) { Hmis::User.find(user.id)&.tap { |u| u.update(hmis_data_source_id: ds1.id) } }
  let(:u1) { Hmis::Hud::User.from_user(hmis_user) }
  let(:u2) do
    user2 = create(:user).tap { |u| u.add_viewable(ds1) }
    hmis_user2 = Hmis::User.find(user2.id)&.tap { |u| u.update(hmis_data_source_id: ds1.id) }
    Hmis::Hud::User.from_user(hmis_user2)
  end
  let!(:o1) { create :hmis_hud_organization, data_source: ds1, user: u1 }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let!(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, client: c1, project: p1, user: u1 }
  let!(:s1) { create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, date_updated: Date.today - 1.day, user: u2 }

  let(:test_input) do
    {
      date_provided: Date.today.strftime('%Y-%m-%d'),
      record_type: Types::HmisSchema::Enums::RecordType.enum_member_for_value(144).first,
      type_provided: Types::HmisSchema::Enums::ServiceTypeProvided.enum_member_for_value('144:3').first,
      sub_type_provided: Types::HmisSchema::Enums::ServiceSubTypeProvided.enum_member_for_value('144:3:1').first,
      other_type_provided: 'Other Type',
      moving_on_other_type: 'Moving On Other Type',
      'FAAmount' => 1.5,
      referral_outcome: Types::HmisSchema::Enums::PATHReferralOutcome.enum_member_for_value(1).first,
    }
  end

  before(:each) do
    post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation UpdateService($id: ID!, $input: ServiceInput!) {
        updateService(input: { input: $input, id: $id }) {
          service {
            id
            enrollment {
              id
            }
            client {
              id
            }
            dateProvided
            recordType
            typeProvided
            subTypeProvided
            otherTypeProvided
            movingOnOtherType
            FAAmount
            referralOutcome
            dateUpdated
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

  it 'should update a service successfully' do
    prev_date_updated = s1.date_updated
    expect(s1.user_id).to eq(u2.user_id)

    response, result = post_graphql(input: test_input, id: s1.id) { mutation }

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
    expect(Date.parse(service['dateUpdated'])).to eq(Date.today)
    expect(errors).to be_empty
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end

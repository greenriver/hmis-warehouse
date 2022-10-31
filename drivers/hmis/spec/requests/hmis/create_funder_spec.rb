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
  let!(:o1) { create :hmis_hud_organization, data_source_id: ds1.id, user: u1 }
  let!(:p1) { create :hmis_hud_project, data_source_id: ds1.id, organization: o1, user: u1 }
  let(:valid_input) do
    {
      project_id: p1.id,
      grant_id: 'grant',
      funder: Types::HmisSchema::Enums::FundingSource.enum_member_for_value(30).first,
      start_date: '2022-01-01',
    }
  end

  describe 'funder creation' do
    before(:each) do
      post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
    end

    let(:mutation) do
      <<~GRAPHQL
        mutation CreateFunder($input: FunderInput!) {
          createFunder(input: { input: $input }) {
            funder {
              id
              funder
              grantId
              startDate
              endDate
              otherFunder
              dateCreated
              dateUpdated
              dateDeleted
              active
            }
            errors {
              attribute
              type
              fullMessage
              message
            }
          }
        }
      GRAPHQL
    end

    it 'creates funder successfully' do
      response, result = post_graphql(input: valid_input) { mutation }

      expect(response.status).to eq 200
      record = result.dig('data', 'createFunder', 'funder')
      errors = result.dig('data', 'createFunder', 'errors')
      expect(errors).to be_empty
      expect(record['id']).to be_present
      expect(record['active']).to eq(true)

      funder = Hmis::Hud::Funder.find(record['id'])
      expect(funder.start_date).to be_present
      expect(funder.funder).to eq(30)
    end

    it 'creates funder with other_funder successfully' do
      response, result = post_graphql(
        input: {
          **valid_input,
          funder: Types::HmisSchema::Enums::FundingSource.enum_member_for_value(46).first,
          other_funder: 'Another funder',
        },
      ) { mutation }

      expect(response.status).to eq 200
      record = result.dig('data', 'createFunder', 'funder')
      errors = result.dig('data', 'createFunder', 'errors')
      expect(errors).to be_empty
      expect(record['id']).to be_present
    end

    it 'fails if other_funder is missing when required' do
      response, result = post_graphql(
        input: {
          **valid_input,
          funder: Types::HmisSchema::Enums::FundingSource.enum_member_for_value(46).first,
          other_funder: '',
        },
      ) { mutation }

      record = result.dig('data', 'createFunder', 'funder')
      errors = result.dig('data', 'createFunder', 'errors')

      expect(response.status).to eq 200
      expect(record).to be_nil
      expect(errors).to be_present
      expect(errors[0]['attribute']).to eq 'otherFunder'
      expect(errors[0]['type']).to eq 'required'
    end

    it 'fails if grant id is missing' do
      response, result = post_graphql(input: { **valid_input, grant_id: '' }) { mutation }

      record = result.dig('data', 'createFunder', 'funder')
      errors = result.dig('data', 'createFunder', 'errors')

      expect(response.status).to eq 200
      expect(record).to be_nil
      expect(errors).to be_present
      expect(errors[0]['attribute']).to eq 'grantId'
      expect(errors[0]['type']).to eq 'required'
    end

    it 'fails if start date is missing' do
      response, result = post_graphql(input: { **valid_input, start_date: nil }) { mutation }

      record = result.dig('data', 'createFunder', 'funder')
      errors = result.dig('data', 'createFunder', 'errors')

      expect(response.status).to eq 200
      expect(record).to be_nil
      expect(errors).to be_present
      expect(errors[0]['attribute']).to eq 'startDate'
      expect(errors[0]['type']).to eq 'required'
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end

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
  let(:access_group) { create :edit_access_group }

  let(:valid_input) do
    {
      project_id: p1.id,
      grant_id: 'grant',
      funder: Types::HmisSchema::Enums::FundingSource.enum_member_for_value(24).first,
      start_date: '2022-01-01',
    }
  end

  describe 'funder update' do
    let!(:f1) { create :hmis_hud_funder, data_source_id: ds1.id, project: p1 }

    before(:each) do
      post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
      access_group.add_viewable(p1.as_warehouse)
      access_group.add(hmis_user)
    end

    let(:mutation) do
      <<~GRAPHQL
        mutation UpdateFunder($id: ID!, $input: FunderInput!) {
          updateFunder(input: { input: $input, id: $id }) {
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

    it 'updates funder successfully' do
      response, result = post_graphql(id: f1.id, input: valid_input) { mutation }

      expect(response.status).to eq 200
      record = result.dig('data', 'updateFunder', 'funder')
      errors = result.dig('data', 'updateFunder', 'errors')
      expect(errors).to be_empty
      expect(record['id']).to be_present
      record = Hmis::Hud::Funder.find(record['id'])
      expect(record.funder).to eq 24
    end

    it 'fails if grant id is null' do
      response, result = post_graphql(id: f1.id, input: { **valid_input, grant_id: nil }) { mutation }

      record = result.dig('data', 'updateFunder', 'funder')
      errors = result.dig('data', 'updateFunder', 'errors')

      expect(response.status).to eq 200
      expect(record).to be_nil
      expect(errors).to be_present
      expect(errors[0]['attribute']).to eq 'grantId'
      expect(errors[0]['type']).to eq 'required'
    end

    it 'fails if grant id is empty string' do
      response, result = post_graphql(id: f1.id, input: { **valid_input, grant_id: '' }) { mutation }

      record = result.dig('data', 'updateFunder', 'funder')
      errors = result.dig('data', 'updateFunder', 'errors')

      expect(response.status).to eq 200
      expect(record).to be_nil
      expect(errors).to be_present
      expect(errors[0]['attribute']).to eq 'grantId'
      expect(errors[0]['type']).to eq 'required'
    end

    it 'fails if 46 and other is missing' do
      response, result = post_graphql(id: f1.id, input: { **valid_input, funder: Types::HmisSchema::Enums::FundingSource.enum_member_for_value(46).first }) { mutation }

      record = result.dig('data', 'updateFunder', 'funder')
      errors = result.dig('data', 'updateFunder', 'errors')

      expect(response.status).to eq 200
      expect(record).to be_nil
      expect(errors).to be_present
      expect(errors[0]['attribute']).to eq 'otherFunder'
      expect(errors[0]['type']).to eq 'required'
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end

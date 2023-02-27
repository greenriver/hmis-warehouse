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

  let(:valid_input) do
    {
      project_id: p1.id,
      grant_id: 'grant',
      funder: Types::HmisSchema::Enums::Hud::FundingSource.enum_member_for_value(24).first,
      start_date: '2022-01-01',
    }
  end

  let!(:f1) { create :hmis_hud_funder, data_source: ds1, project: p1 }

  let(:mutation) do
    <<~GRAPHQL
      mutation UpdateFunder($id: ID!, $input: FunderInput!) {
        updateFunder(input: { input: $input, id: $id }) {
          funder {
            #{scalar_fields(Types::HmisSchema::Funder)}
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  describe 'funder update' do
    before(:each) do
      hmis_login(user)
      assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
    end

    it 'updates funder successfully' do
      response, result = post_graphql(id: f1.id, input: valid_input) { mutation }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        record = result.dig('data', 'updateFunder', 'funder')
        errors = result.dig('data', 'updateFunder', 'errors')
        expect(errors).to be_empty
        expect(record['id']).to be_present
        record = Hmis::Hud::Funder.find(record['id'])
        expect(record.funder).to eq 24
        expect(record.date_created).to eq(f1.date_created)
        expect(record.date_updated).not_to eq(f1.date_updated)
      end
    end

    it 'fails if grant id is null' do
      response, result = post_graphql(id: f1.id, input: { **valid_input, grant_id: nil }) { mutation }

      record = result.dig('data', 'updateFunder', 'funder')
      errors = result.dig('data', 'updateFunder', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(record).to be_nil
        expect(errors).to be_present
        expect(errors[0]['attribute']).to eq 'grantId'
        expect(errors[0]['type']).to eq 'required'
      end
    end

    it 'fails if grant id is empty string' do
      response, result = post_graphql(id: f1.id, input: { **valid_input, grant_id: '' }) { mutation }

      record = result.dig('data', 'updateFunder', 'funder')
      errors = result.dig('data', 'updateFunder', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(record).to be_nil
        expect(errors).to be_present
        expect(errors[0]['attribute']).to eq 'grantId'
        expect(errors[0]['type']).to eq 'required'
      end
    end

    it 'fails if 46 and other is missing' do
      response, result = post_graphql(id: f1.id, input: { **valid_input, funder: Types::HmisSchema::Enums::Hud::FundingSource.enum_member_for_value(46).first }) { mutation }

      record = result.dig('data', 'updateFunder', 'funder')
      errors = result.dig('data', 'updateFunder', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(record).to be_nil
        expect(errors).to be_present
        expect(errors[0]['attribute']).to eq 'otherFunder'
        expect(errors[0]['type']).to eq 'required'
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end

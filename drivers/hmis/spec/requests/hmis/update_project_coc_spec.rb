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
      coc_code: 'CO-500',
      geocode: '123456',
      city: 'test',
      state: 'VT',
      zip: '05055',
    }
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation UpdateProjectCoc($id: ID!, $input: ProjectCocInput!) {
        updateProjectCoc(input: { input: $input, id: $id }) {
          projectCoc {
            id
            cocCode
            geocode
            geographyType
            city
            state
            zip
            dateCreated
            dateUpdated
            dateDeleted
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end
  let!(:pc1) { create :hmis_hud_project_coc, data_source: ds1, project: p1, coc_code: 'CO-503' }

  describe 'projectCoc update with edit access' do
    before(:each) do
      hmis_login(user)
      assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
    end

    it 'updates project coc successfully' do
      response, result = post_graphql(id: pc1.id, input: valid_input) { mutation }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        record = result.dig('data', 'updateProjectCoc', 'projectCoc')
        errors = result.dig('data', 'updateProjectCoc', 'errors')
        expect(errors).to be_empty
        expect(record['id']).to be_present
        record = Hmis::Hud::ProjectCoc.find(record['id'])
        expect(record.coc_code).to eq valid_input[:coc_code]
      end
    end

    it 'should throw error if unauthorized' do
      remove_permissions(hmis_user, :can_edit_project_details)
      response, result = post_graphql(id: pc1.id, input: valid_input) { mutation }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        record = result.dig('data', 'updateProjectCoc', 'projectCoc')
        errors = result.dig('data', 'updateProjectCoc', 'errors')
        expect(errors).to be_present
        expect(record).to be_nil
        expect(errors).to contain_exactly(include('message' => 'operation not allowed'))
        record = Hmis::Hud::ProjectCoc.find(pc1.id)
        expect(record.coc_code).to eq(pc1.coc_code)
      end
    end

    it 'fails if coc code is null' do
      response, result = post_graphql(id: pc1.id, input: { **valid_input, coc_code: nil }) { mutation }

      record = result.dig('data', 'updateProjectCoc', 'projectCoc')
      errors = result.dig('data', 'updateProjectCoc', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(record).to be_nil
        expect(errors).to be_present
        expect(errors[0]['attribute']).to eq 'cocCode'
        expect(errors[0]['type']).to eq 'required'
      end
    end
  end

  describe 'projectCoc update with view access' do
    before(:each) do
      hmis_login(user)
      assign_viewable(view_access_group, p1.as_warehouse, hmis_user)
    end

    it 'should not be able to update project coc' do
      response, result = post_graphql(id: pc1.id, input: valid_input) { mutation }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        record = result.dig('data', 'updateProjectCoc', 'projectCoc')
        errors = result.dig('data', 'updateProjectCoc', 'errors')
        expect(errors).to be_present
        expect(record).to be_blank
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end

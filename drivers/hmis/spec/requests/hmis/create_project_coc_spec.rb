require 'rails_helper'
require_relative 'login_and_permissions'
require_relative 'hmis_base_setup'

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

  describe 'project_coc creation' do
    before(:each) do
      hmis_login(user)
      assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
    end

    let(:mutation) do
      <<~GRAPHQL
        mutation CreateProjectCoc($input: ProjectCocInput!) {
          createProjectCoc(input: { input: $input }) {
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

    it 'creates project_coc successfully' do
      response, result = post_graphql(input: valid_input) { mutation }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        record = result.dig('data', 'createProjectCoc', 'projectCoc')
        errors = result.dig('data', 'createProjectCoc', 'errors')
        expect(errors).to be_empty
        expect(record['id']).to be_present

        project_coc = Hmis::Hud::ProjectCoc.find(record['id'])
        expect(project_coc.coc_code).to be_present
        expect(project_coc.project).to eq(p1)
      end
    end

    it 'fails if coc code or geocode is missing' do
      [:coc_code, :geocode].each do |field|
        response, result = post_graphql(input: { **valid_input, field => nil }) { mutation }

        record = result.dig('data', 'createProjectCoc', 'projectCoc')
        errors = result.dig('data', 'createProjectCoc', 'errors')

        aggregate_failures 'checking response' do
          expect(response.status).to eq 200
          expect(record).to be_nil
          expect(errors).to be_present
          expect(errors[0]['attribute']).to eq field.to_s.camelize(:lower)
          expect(errors[0]['type']).to eq 'required'
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end

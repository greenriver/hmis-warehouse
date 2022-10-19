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
      coc_code: 'CO-500',
      geocode: '123456',
      city: 'test',
      state: 'VT',
      zip: '05055',
    }
  end

  describe 'project_coc creation' do
    before(:each) do
      post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
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

    it 'creates project_coc successfully' do
      response, result = post_graphql(input: valid_input) { mutation }

      expect(response.status).to eq 200
      record = result.dig('data', 'createProjectCoc', 'projectCoc')
      errors = result.dig('data', 'createProjectCoc', 'errors')
      expect(errors).to be_empty
      expect(record['id']).to be_present

      project_coc = Hmis::Hud::ProjectCoc.find(record['id'])
      expect(project_coc.coc_code).to be_present
      expect(project_coc.project).to eq(p1)
    end

    it 'fails if coc code or geocode is missing' do
      [:coc_code, :geocode].each do |field|
        response, result = post_graphql(input: { **valid_input, field => nil }) { mutation }

        record = result.dig('data', 'createProjectCoc', 'projectCoc')
        errors = result.dig('data', 'createProjectCoc', 'errors')

        expect(response.status).to eq 200
        expect(record).to be_nil
        expect(errors).to be_present
        expect(errors[0]['attribute']).to eq field.to_s.camelize(:lower)
        expect(errors[0]['type']).to eq 'required'
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end

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
      coc_code: 'CO-500',
      geocode: '123456',
      city: 'test',
      state: 'VT',
      zip: '05055',
    }
  end

  describe 'projectCoc update' do
    let!(:pc1) { create :hmis_hud_project_coc, data_source_id: ds1.id, project: p1, coc_code: 'CO-503' }

    before(:each) do
      post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
      access_group.add_viewable(p1.as_warehouse)
      access_group.add(hmis_user)
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

    it 'updates project coc successfully' do
      response, result = post_graphql(id: pc1.id, input: valid_input) { mutation }

      expect(response.status).to eq 200
      record = result.dig('data', 'updateProjectCoc', 'projectCoc')
      errors = result.dig('data', 'updateProjectCoc', 'errors')
      expect(errors).to be_empty
      expect(record['id']).to be_present
      record = Hmis::Hud::ProjectCoc.find(record['id'])
      expect(record.coc_code).to eq valid_input[:coc_code]
    end

    it 'fails if coc code is null' do
      response, result = post_graphql(id: pc1.id, input: { **valid_input, coc_code: nil }) { mutation }

      record = result.dig('data', 'updateProjectCoc', 'projectCoc')
      errors = result.dig('data', 'updateProjectCoc', 'errors')

      expect(response.status).to eq 200
      expect(record).to be_nil
      expect(errors).to be_present
      expect(errors[0]['attribute']).to eq 'cocCode'
      expect(errors[0]['type']).to eq 'required'
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end

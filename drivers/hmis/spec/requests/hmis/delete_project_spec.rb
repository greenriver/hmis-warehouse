#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

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
  let!(:access_control) { create_access_control(hmis_user, p1) }
  let!(:p2) { create :hud_project, data_source_id: ds1.id, OrganizationID: o1.OrganizationID }

  let(:delete_mutation) do
    <<~GRAPHQL
      mutation DeleteProject($id: ID!) {
        deleteProject(input: { id: $id }) {
          project {
            id
            projectName
            projectType
          }
          errors {
            type
            message
          }
        }
      }
    GRAPHQL
  end

  describe 'delete project query' do
    before(:each) do
      hmis_login(user)
    end

    it 'should successfully delete' do
      response, result = post_graphql({ id: p1.id }) { delete_mutation }
      expect(response.status).to eq(200)
      deleted_project = result.dig('data', 'deleteProject', 'project')
      expect(deleted_project).not_to be_nil
      expect(deleted_project['id']).to eq(p1.id.to_s)
      p1.reload
      expect(p1.date_deleted).not_to be_nil
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end

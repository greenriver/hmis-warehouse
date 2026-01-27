###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'DeleteProject mutation', type: :request do
  include_context 'hmis base setup'
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

  before(:each) do
    hmis_login(user)
  end

  context 'when user is authorized to delete project' do
    let!(:access_control) { create_access_control(hmis_user, p1, with_permission: [:can_view_project, :can_delete_project]) }
    it 'should successfully delete' do
      response, result = post_graphql({ id: p1.id }) { delete_mutation }
      expect(response.status).to eq(200), result.inspect
      deleted_project = result.dig('data', 'deleteProject', 'project')
      expect(deleted_project).not_to be_nil
      expect(deleted_project['id']).to eq(p1.id.to_s)
      p1.reload
      expect(p1.date_deleted).not_to be_nil
    end
  end

  context 'when user is not authorized to view project' do
    let!(:access_control) { create_access_control(hmis_user, p1, without_permission: :can_view_project) }
    it 'should raise' do
      expect_access_denied post_graphql({ id: p1.id }) { delete_mutation }
    end
  end

  context 'when user is not authorized to delete project' do
    let!(:access_control) { create_access_control(hmis_user, p1, without_permission: :can_delete_project) }
    it 'should raise' do
      expect_access_denied post_graphql({ id: p1.id }) { delete_mutation }
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end

###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let!(:ds_access_control) do
    create_access_control(hmis_user, ds1, with_permission: [:can_view_clients, :can_view_dob, :can_view_enrollment_details])
  end

  before(:each) do
    hmis_login(user)
  end

  let!(:enrollment) do
    client = create :hmis_hud_client_complete, data_source: ds1, user: u1
    create :hmis_hud_enrollment, data_source: ds1, project: p1, client: client, user: u1
  end

  describe 'client reminders' do
    let(:query) do
      <<~GRAPHQL
        query GetClient($id: ID!) {
          client(id: $id) {
            id
            recommendations {
              id
              description
              dueDate
            }
          }
        }
      GRAPHQL
    end
    let(:variables) do
      {
        clientId: enrollment.client.id,
      }
    end

    it 'returns recommendations' do
      _, result = post_graphql(**variables) { query }
      byebug
      expect(result.dig('data', 'client', 'recommendations').size).to eq(1)
    end
  end
end
RSpec.configure do |c|
  c.include GraphqlHelpers
end

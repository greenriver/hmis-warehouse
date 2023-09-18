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
    create_access_control(hmis_user, ds1, with_permission: [:can_view_clients, :can_view_dob, :can_view_project, :can_view_enrollment_details])
  end

  before(:each) do
    hmis_login(user)
  end

  let!(:enrollment) do
    client = create :hmis_hud_client_complete, data_source: ds1, user: u1
    hoh = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: client, user: u1, relationship_to_hoh: 1
    3.times do
      member = create :hmis_hud_client_complete, data_source: ds1, user: u1
      create :hmis_hud_enrollment, data_source: ds1, project: p1, client: member, user: u1, relationship_to_hoh: 99
    end
    hoh
  end

  describe 'client reminders' do
    let(:query) do
      <<~GRAPHQL
        query GetEnrollment($id: ID!) {
          enrollment(id: $id) {
            id
            reminders {
              id
              topic
              dueDate
              overdue
              enrollment {
                id
              }
              client {
                id
              }
            }
          }
        }
      GRAPHQL
    end
    let(:variables) do
      {
        id: enrollment.id,
      }
    end

    it 'minimizes n+1 queries' do
      expect do
        _, result = post_graphql(**variables) { query }
        expect(result.dig('data', 'enrollment', 'reminders').size).to eq(1)
      end.to make_database_queries(count: 10..20)
    end

    it 'is responsive' do
      expect do
        _, result = post_graphql(**variables) { query }
        expect(result.dig('data', 'enrollment', 'reminders').size).to eq(1)
      end.to perform_under(300).ms
    end
  end
end
RSpec.configure do |c|
  c.include GraphqlHelpers
end

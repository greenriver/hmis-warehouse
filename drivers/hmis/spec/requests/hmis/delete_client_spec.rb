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
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c2) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1, household_id: '1', user: u1 }

  before(:each) do
    hmis_login(user)
    assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation DeleteClient($input: DeleteClientInput!) {
        deleteClient(input: $input) {
          client {
            id
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  it 'should delete a client who has no multi-person enrollments' do
    response, result = post_graphql(input: { id: c1.id }) { mutation }
    aggregate_failures 'checking response' do
      # byebug
      expect(Hmis::Hud::Client.all).to include(
        have_attributes(id: c1.id),
      )
      expect(response.status).to eq 200
      client = result.dig('data', 'deleteClient', 'client')
      errors = result.dig('data', 'deleteClient', 'errors')
      expect(client).to be_present
      expect(errors).to be_empty
      expect(Hmis::Hud::Client.all).not_to include(
        have_attributes(id: c1.id),
      )
    end
  end

  # it 'should throw error if unauthorized' do
  #   remove_permissions(hmis_user, :can_delete_enrollments)
  #   response, result = post_graphql(input: { id: e2.id }) { mutation }

  #   aggregate_failures 'checking response' do
  #     expect(response.status).to eq 200
  #     enrollment = result.dig('data', 'deleteEnrollment', 'enrollment')
  #     errors = result.dig('data', 'deleteEnrollment', 'errors')
  #     expect(enrollment).to be_nil
  #     expect(errors).to contain_exactly(include('type' => 'not_allowed'))
  #     expect(Hmis::Hud::Enrollment.all).to contain_exactly(
  #       have_attributes(id: e1.id),
  #       have_attributes(id: e2.id),
  #     )
  #   end
  # end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end

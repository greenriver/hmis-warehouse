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
  let!(:access_control) { create_access_control(hmis_user, p1, with_permission: [:can_view_project, :can_view_enrollment_details, :can_view_clients]) }
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c2) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1 }
  let!(:e2) { create :hmis_hud_wip_enrollment, data_source: ds1, project: p1, client: c2, relationship_to_ho_h: 2, household_id: e1.household_id }

  let(:query) do
    <<~GRAPHQL
      mutation UpdateBedNights($input: UpdateBedNightsInput!) {
        updateBedNights(input: $input) {
          success
          errors {
            id
          }
        }
      }
    GRAPHQL
  end

  describe 'update bed night mutations' do
    include_context 'with paper trail'
    before(:each) do
      hmis_login(user)
    end

    let(:mutation_input) do
      {
        "input": {
          "projectId": p1.id,
          "enrollmentIds": [e1.id, e2.id],
          "action": 'ADD',
          "bedNightDate": Date.current.to_s(:db),
        },
      }
    end

    it 'assigns service' do
      services = Hmis::Hud::Service.bed_nights
      expect do
        response, = post_graphql(mutation_input) { query }
        expect(response.status).to eq 200
      end.to change(services, :count).by(2)
    end

    it 'tracks version' do
      e1_versions = GrdaWarehouse.paper_trail_versions.where(enrollment_id: e1.id)
      e2_versions = GrdaWarehouse.paper_trail_versions.where(enrollment_id: e2.id)
      expect do
        response, = post_graphql(mutation_input) { query }
        expect(response.status).to eq 200
      end.to change(e1_versions, :count).by(1).
        and change(e2_versions, :count).by(1)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end

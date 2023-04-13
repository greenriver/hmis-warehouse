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
  let(:c3) { create :hmis_hud_client, data_source: ds1, user: u1 }
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

  def mutate(**kwargs)
    response, result = post_graphql(**kwargs) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      client = result.dig('data', 'deleteClient', 'client')
      errors = result.dig('data', 'deleteClient', 'errors')
      yield client, errors
    end
  end

  it 'should delete a client who has no multi-person enrollments' do
    expect(Hmis::Hud::Client.all).to include(have_attributes(id: c1.id))

    mutate(input: { id: c1.id }) do |client, errors|
      expect(client).to be_present
      expect(errors).to be_empty
      expect(Hmis::Hud::Client.all).not_to include(have_attributes(id: c1.id))
    end
  end

  it 'should delete a client who has a 2-person enrollment' do
    e2 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, relationship_to_ho_h: 2, household_id: '1', user: u1

    mutate(input: { id: c1.id }) do |client, errors|
      expect(client).to be_present
      expect(errors).to be_empty
      expect(Hmis::Hud::Client.all).to contain_exactly(have_attributes(id: c2.id))
      expect(e2.reload.relationship_to_ho_h).to eq(1)
    end
  end

  it 'should warn when trying to delete a client who has a 3+ person enrollment' do
    e2 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, relationship_to_ho_h: 2, household_id: '1', user: u1
    e3 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, relationship_to_ho_h: 2, household_id: '1', user: u1

    mutate(input: { id: c1.id }) do |client, errors|
      expect(client).to be_nil
      expect(errors).to contain_exactly(
        include(
          'type' => 'information',
          'severity' => 'warning',
          'data' => include(
            'enrollments' => contain_exactly(
              include(
                'id' => e1.id.to_s,
                'entryDate' => e1.entry_date&.to_s(:db),
                'exitDate' => e1.exit_date&.to_s(:db),
                'name' => e1.project.project_name,
              ),
            ),
          ),
        ),
      )
      expect(Hmis::Hud::Client.all).to include(have_attributes(id: c1.id))
    end

    # Shoud be able to bypass it
    mutate(input: { id: c1.id, confirmed: true }) do |client, errors|
      expect(client).to be_present
      expect(errors).to be_empty
      expect(Hmis::Hud::Client.all).not_to include(have_attributes(id: c1.id))
      # HoH shouldn't have changed for household
      [e2, e3].each { |e| expect(e.relationship_to_ho_h).not_to eq(1) }
    end
  end

  it 'should throw error if unauthorized' do
    remove_permissions(hmis_user, :can_delete_clients)
    e2 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, relationship_to_ho_h: 2, household_id: '1', user: u1
    prev_hoh_value = e2.relationship_to_ho_h

    mutate(input: { id: c1.id }) do |client, errors|
      expect(client).to be_nil
      expect(errors).to contain_exactly(include('type' => 'not_allowed'))
      expect(Hmis::Hud::Client.all).to include(have_attributes(id: c1.id))
      # Should NOT modify HoH of other enrollments if client is not deleted
      expect(e2.reload.relationship_to_ho_h).to eq(prev_hoh_value)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end

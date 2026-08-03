###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  let!(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1 }

  before(:each) { hmis_login(user) }

  let(:query) do
    <<~GRAPHQL
      query Enrollment($id: ID!) {
        enrollment(id: $id) {
          id
          currentUnit {
            id
          }
          numUnitsAssignedToHousehold
        }
      }
    GRAPHQL
  end

  it 'resolves the current unit and number of units assigned to household' do
    # Put e1 in unit1
    unit1 = create(:hmis_unit, project: p1)
    create(:hmis_unit_occupancy, unit: unit1, enrollment: e1, start_date: e1.entry_date)
    # Put e3 and e4 in unit2
    unit2 = create(:hmis_unit, project: p1)
    e3 = create(:hmis_hud_enrollment, data_source: ds1, project: p1, household_id: e1.household_id)
    create(:hmis_unit_occupancy, unit: unit2, enrollment: e3, start_date: e3.entry_date)
    e4 = create(:hmis_hud_enrollment, data_source: ds1, project: p1, household_id: e1.household_id, entry_date: 2.weeks.ago)
    create(:hmis_unit_occupancy, unit: unit2, enrollment: e4, start_date: e4.entry_date + 2.days)
    # previous occupancy in another unit should not be counted
    create(:hmis_unit_occupancy, enrollment: e4, start_date: e4.entry_date, end_date: e4.entry_date + 2.day)

    response, result = post_graphql(id: e1.id) { query }
    expect(response.status).to eq(200), result.inspect
    enrollment = result.dig('data', 'enrollment')
    expect(enrollment['id']).to eq(e1.id.to_s)
    expect(enrollment['currentUnit']['id']).to eq(unit1.id.to_s)
    expect(enrollment['numUnitsAssignedToHousehold']).to eq(2)
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/enrollment_rollup_context'

RSpec.describe ClientHistory::EnrollmentView, type: :model do
  include_context 'enrollment rollup context'

  let!(:affiliation) do
    create(
      :hud_affiliation,
      data_source_id: data_source.id,
      ProjectID: shelter_a.ProjectID,
      ResProjectID: housing.ProjectID,
    )
  end
  let(:view) { described_class.new(user: user) }
  let(:shelter_a_row) { { ProjectID: shelter_a.ProjectID, data_source_id: data_source.id } }
  let(:housing_row) { { ProjectID: housing.ProjectID, data_source_id: data_source.id } }
  let(:shelter_b_row) { { ProjectID: shelter_b.ProjectID, data_source_id: data_source.id } }

  it 'names the residential project a services project is affiliated with' do
    expect(view.program_tooltip_data_for_enrollment(shelter_a_row)).to eq('bs-toggle' => :tooltip, title: 'Affiliated with Housing')
  end

  it 'names the services project a residential project is affiliated with' do
    expect(view.program_tooltip_data_for_enrollment(housing_row)).to eq('bs-toggle' => :tooltip, title: 'Affiliated with Shelter A')
  end

  it 'returns an empty hash for an unaffiliated project' do
    expect(view.program_tooltip_data_for_enrollment(shelter_b_row)).to eq({})
  end

  it 'loads affiliations once per user, not once per enrollment' do
    view.program_tooltip_data_for_enrollment(shelter_a_row)
    queries = count_database_queries do
      3.times { view.program_tooltip_data_for_enrollment(housing_row) }
      3.times { view.program_tooltip_data_for_enrollment(shelter_b_row) }
    end
    expect(queries).to eq(0)
  end

  it 'reuses one view per user across enrollments on the client' do
    destination_client.program_tooltip_data_for_enrollment(shelter_a_row, user)
    queries = count_database_queries do
      destination_client.program_tooltip_data_for_enrollment(housing_row, user)
      destination_client.program_tooltip_data_for_enrollment(shelter_b_row, user)
    end
    expect(queries).to eq(0)
  end
end

###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'CasCeData::Synthetic::Event', type: :model do
  let!(:data_source) { create :grda_warehouse_data_source }
  let!(:project) { create :hud_project, data_source_id: data_source.id, ProjectType: 13, computed_project_type: 13, ContinuumProject: 1 }
  let!(:source_client) { create :hud_client, data_source_id: data_source.id }
  let!(:enrollment) { create :hud_enrollment, data_source_id: data_source.id, PersonalID: source_client.PersonalID, ProjectID: project.ProjectID }

  let!(:destination_data_source) { create :destination_data_source }
  let!(:destination_client) { create :hud_client, data_source_id: destination_data_source.id }
  let!(:warehouse_client) { create :warehouse_client, source_id: source_client.id, destination_id: destination_client.id }

  let!(:mapping) { create :program_to_project, project_id: project.id }
  let!(:cas_referral_event) { create :cas_referral_event, hmis_client_id: destination_client.id, program_id: mapping.program_id, referral_date: enrollment.EntryDate, event: 14 }

  it 'creates events from cas referral event' do
    expect(CasCeData::Synthetic::Event.count).to eq(0)
    CasCeData::Synthetic::Event.sync
    expect(GrdaWarehouse::Synthetic::Event.count).to eq(1)
    GrdaWarehouse::Synthetic::Event.create_hud_events
    expect(GrdaWarehouse::Hud::Event.count).to eq(1)
  end
end

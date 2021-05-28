###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'Synthetic VI-SPDAT sync', type: :model do
  let!(:data_source) { create :data_source_fixed_id }
  let!(:project) { create :hud_project, data_source_id: data_source.id }
  let!(:client) { create :hud_client, data_source_id: data_source.id }
  let!(:enrollment) { create :hud_enrollment, PersonalID: client.PersonalID, ProjectID: project.ProjectID, data_source_id: data_source.id }
  let!(:service_history_enrollment) do
    create :grda_warehouse_service_history, :service_history_entry,
           project_id: project.ProjectID, client_id: client.id, enrollment_group_id: enrollment.EnrollmentID,
           first_date_in_program: Date.yesterday, data_source_id: data_source.id
  end

  let!(:agency) { create :agency }
  let!(:user) { create :user, agency_id: agency.id }

  let!(:vispdat1) { create :vispdat, client_id: client.id, user_id: user.id, submitted_at: Date.today }
  let!(:vispdat2) { create :vispdat, client_id: client.id, user_id: user.id, submitted_at: Date.today }
  let!(:vispdat3) { create :vispdat, client_id: client.id, user_id: user.id }

  it 'creates synthetic assessments for completed VI-SPDATs' do
    Vispdats::Synthetic::Base.sync
    expect(Vispdats::Synthetic::Base.count).to eq(2)
  end

  it 'removes orphaned synthetic assessments' do
    Vispdats::Synthetic::Base.sync
    expect(Vispdats::Synthetic::Base.count).to eq(2)

    # TODO remove a VI-SPDAT
    count = Vispdats::Synthetic::Base.count
    vispdat1.destroy
    Vispdats::Synthetic::Base.sync
    expect(Vispdats::Synthetic::Base.count).to eq(count - 1)
  end

  it 'adds a new VI-SPDAT' do
    Vispdats::Synthetic::Base.sync
    expect(Vispdats::Synthetic::Base.count).to eq(2)

    # TODO add a VI-SPDAT
    count = Vispdats::Synthetic::Base.count
    create(:vispdat, client_id: client.id, user_id: user.id, submitted_at: Date.today)
    Vispdats::Synthetic::Base.sync
    expect(Vispdats::Synthetic::Base.count).to eq(count + 1)
  end
end

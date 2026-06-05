###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::Builders::ClsBuilder do
  let!(:data_source) { create(:hmis_data_source) }
  let(:user_id) do
    User.setup_system_user
    Hmis::Hud::User.system_user(data_source_id: data_source.id).user_id
  end
  let(:date)       { Date.current - 1 }
  let(:client)     { create(:hmis_hud_client, data_source: data_source) }
  let(:project)    { create(:hmis_hud_project, data_source: data_source) }
  let(:enrollment) { create(:hmis_hud_enrollment, data_source: data_source, client: client, project: project, EntryDate: date - 30) }

  subject(:builder) do
    described_class.new(
      enrollment: enrollment,
      date: date,
      situation_code: 116,
      data_source: data_source,
      user_id: user_id,
    )
  end

  describe '#build!' do
    it 'creates an Hmis::Hud::CurrentLivingSituation record' do
      expect { builder.build! }.to change { Hmis::Hud::CurrentLivingSituation.where(data_source: data_source).count }.by(1)
    end

    it 'uses a FAKE CurrentLivingSitID' do
      expect(builder.build!.CurrentLivingSitID).to start_with('FAKE')
    end

    it 'sets CurrentLivingSituation to the provided code' do
      expect(builder.build!.CurrentLivingSituation).to eq(116)
    end

    it 'sets InformationDate to the given date' do
      expect(builder.build!.InformationDate).to eq(date)
    end

    it 'links to the correct enrollment and client' do
      result = builder.build!
      expect(result.EnrollmentID).to eq(enrollment.EnrollmentID)
      expect(result.PersonalID).to eq(client.PersonalID)
    end
  end
end

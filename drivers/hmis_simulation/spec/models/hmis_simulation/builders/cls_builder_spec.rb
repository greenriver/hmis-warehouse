###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::Builders::ClsBuilder do
  include_context 'hmis simulation builder setup'

  let(:date) { Date.current - 1 }

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

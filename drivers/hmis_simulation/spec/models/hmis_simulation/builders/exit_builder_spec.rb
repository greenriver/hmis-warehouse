###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::Builders::ExitBuilder do
  let!(:data_source) { create(:hmis_data_source) }
  let(:user_id) do
    User.setup_system_user
    Hmis::Hud::User.system_user(data_source_id: data_source.id).user_id
  end
  let(:entry_date) { Date.current - 30 }
  let(:date)       { Date.current - 1 }
  let(:client)     { create(:hmis_hud_client, data_source: data_source) }
  let(:project)    { create(:hmis_hud_project, data_source: data_source) }
  let(:enrollment) { create(:hmis_hud_enrollment, data_source: data_source, client: client, project: project, EntryDate: entry_date) }

  subject(:builder) do
    described_class.new(
      enrollment: enrollment,
      exit_date: date,
      exit_destinations: { '435' => 0.7, '426' => 0.3 },
      data_source: data_source,
      user_id: user_id,
      seed: 42,
      context_prefix: 'test:exit:0',
    )
  end

  describe '#build!' do
    it 'creates an Hmis::Hud::Exit record' do
      expect { builder.build! }.to change { Hmis::Hud::Exit.where(data_source: data_source).count }.by(1)
    end

    it 'uses a FAKE ExitID' do
      result = builder.build!
      expect(result.ExitID).to start_with('FAKE')
    end

    it 'sets ExitDate to the provided date' do
      result = builder.build!
      expect(result.ExitDate).to eq(date)
    end

    it 'links to the correct enrollment via EnrollmentID' do
      result = builder.build!
      expect(result.EnrollmentID).to eq(enrollment.EnrollmentID)
    end

    it 'sets Destination to one of the weighted values' do
      result = builder.build!
      expect([435, 426]).to include(result.Destination)
    end

    it 'samples destinations proportionally' do
      destinations = 100.times.map do |i|
        described_class.new(
          enrollment: enrollment,
          exit_date: date,
          exit_destinations: { '435' => 1, '426' => 0 },
          data_source: data_source,
          user_id: user_id,
          seed: 42,
          context_prefix: "test:exit:#{i}",
        ).build!.Destination
      end
      expect(destinations.uniq).to eq([435])
    end
  end
end

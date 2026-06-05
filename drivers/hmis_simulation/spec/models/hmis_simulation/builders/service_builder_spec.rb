###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::Builders::ServiceBuilder do
  let!(:data_source) { create(:hmis_data_source) }
  let(:user_id) do
    User.setup_system_user
    Hmis::Hud::User.system_user(data_source_id: data_source.id).user_id
  end
  let(:date)       { Date.current - 1 }
  let(:client)     { create(:hmis_hud_client, data_source: data_source) }
  let(:project)    { create(:hmis_hud_project, data_source: data_source, ProjectType: 1) }
  let(:enrollment) { create(:hmis_hud_enrollment, data_source: data_source, client: client, project: project, EntryDate: date - 1) }

  subject(:builder) do
    described_class.new(
      enrollment: enrollment,
      date: date,
      data_source: data_source,
      user_id: user_id,
    )
  end

  describe '#build_bed_night!' do
    it 'creates one Hmis::Hud::Service record' do
      expect { builder.build_bed_night! }.to change { Hmis::Hud::Service.where(data_source: data_source).count }.by(1)
    end

    it 'uses a FAKE ServicesID' do
      result = builder.build_bed_night!
      expect(result.ServicesID).to start_with('FAKE')
    end

    it 'sets DateProvided to the given date' do
      result = builder.build_bed_night!
      expect(result.DateProvided).to eq(date)
    end

    it 'sets RecordType to 200 (bed night)' do
      result = builder.build_bed_night!
      expect(result.RecordType).to eq(200)
    end

    it 'sets TypeProvided to 200 (bed night)' do
      result = builder.build_bed_night!
      expect(result.TypeProvided).to eq(200)
    end

    it 'links to the correct enrollment and client' do
      result = builder.build_bed_night!
      expect(result.EnrollmentID).to eq(enrollment.EnrollmentID)
      expect(result.PersonalID).to eq(client.PersonalID)
    end
  end
end

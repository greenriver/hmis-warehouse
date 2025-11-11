###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Util::TransferEnrollment, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:from_client) { create(:hmis_hud_client_complete, data_source: data_source) }
  let(:to_client) { create(:hmis_hud_client_complete, data_source: data_source) }
  let(:project) { create(:hmis_hud_project, data_source: data_source) }
  let(:enrollment) { create(:hmis_hud_enrollment, client: from_client, project: project, data_source: data_source) }
  let!(:service) { create(:hmis_hud_service, enrollment: enrollment, client: from_client, data_source: data_source) }
  let!(:assessment) { create(:hmis_hud_assessment, enrollment: enrollment, client: from_client, data_source: data_source) }

  describe '#initialize' do
    it 'raises error if enrollment is missing' do
      expect do
        described_class.new(enrollment: nil, to_client: to_client)
      end.to raise_error(ArgumentError, 'Enrollment must be provided')
    end

    it 'raises error if to_client is missing' do
      expect do
        described_class.new(enrollment: enrollment, to_client: nil)
      end.to raise_error(ArgumentError, 'To client must be provided')
    end

    it 'raises error if clients are in different data sources' do
      other_data_source = create(:hmis_data_source)
      other_client = create(:hmis_hud_client_complete, data_source: other_data_source)
      expect do
        described_class.new(enrollment: enrollment, to_client: other_client)
      end.to raise_error(ArgumentError, 'Clients must be in the same data source')
    end
  end

  describe '#transfer!' do
    it 'transfers enrollment to new client' do
      described_class.new(
        enrollment: enrollment,
        to_client: to_client,
      ).transfer!

      enrollment.reload
      expect(enrollment.personal_id).to eq(to_client.personal_id)
      expect(enrollment.client).to eq(to_client)
    end

    it 'updates associated records PersonalIDs' do
      described_class.new(
        enrollment: enrollment,
        to_client: to_client,
      ).transfer!

      service.reload
      assessment.reload

      expect(service.personal_id).to eq(to_client.personal_id)
      expect(assessment.personal_id).to eq(to_client.personal_id)
    end

    it 'only updates records for the specific enrollment' do
      other_enrollment = create(:hmis_hud_enrollment, client: from_client, project: project, data_source: data_source)
      other_service = create(:hmis_hud_service, enrollment: other_enrollment, client: from_client, data_source: data_source)

      described_class.new(
        enrollment: enrollment,
        to_client: to_client,
      ).transfer!

      service.reload
      other_service.reload

      expect(service.personal_id).to eq(to_client.personal_id)
      expect(other_service.personal_id).to eq(from_client.personal_id)
    end
  end
end


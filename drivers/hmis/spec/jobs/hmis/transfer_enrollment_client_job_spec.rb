###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::TransferEnrollmentClientJob, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:from_client) { create(:hmis_hud_client_complete, data_source: data_source) }
  let(:to_client) { create(:hmis_hud_client_complete, data_source: data_source) }
  let(:project) { create(:hmis_hud_project, data_source: data_source) }
  let(:enrollment) { create(:hmis_hud_enrollment, client: from_client, project: project, data_source: data_source) }
  let!(:service) { create(:hmis_hud_service, enrollment: enrollment, client: from_client, data_source: data_source) }
  let!(:assessment) { create(:hmis_hud_assessment, enrollment: enrollment, client: from_client, data_source: data_source) }

  describe '#perform' do
    it 'raises error if enrollment is missing' do
      expect do
        described_class.perform_now(enrollment_id: nil, to_client_id: to_client.id)
      end.to raise_error(ArgumentError, 'Enrollment must be provided')
    end

    it 'raises error if to_client is missing' do
      expect do
        described_class.perform_now(enrollment_id: enrollment.id, to_client_id: nil)
      end.to raise_error(ArgumentError, 'To client must be provided')
    end

    it 'raises error if clients are in different data sources' do
      other_data_source = create(:hmis_data_source)
      other_client = create(:hmis_hud_client_complete, data_source: other_data_source)

      expect do
        described_class.perform_now(enrollment_id: enrollment.id, to_client_id: other_client.id)
      end.to raise_error(ArgumentError, 'Clients must be in the same data source')
    end

    it 'transfers enrollment to new client' do
      described_class.perform_now(enrollment_id: enrollment.id, to_client_id: to_client.id)

      enrollment.reload
      expect(enrollment.personal_id).to eq(to_client.personal_id)
      expect(enrollment.client).to eq(to_client)
    end

    it 'updates associated records PersonalIDs' do
      expect do
        described_class.perform_now(enrollment_id: enrollment.id, to_client_id: to_client.id)
        [enrollment, service, assessment].each(&:reload)
      end.to change(service, :personal_id).from(from_client.personal_id).to(to_client.personal_id).
        and change(assessment, :personal_id).from(from_client.personal_id).to(to_client.personal_id).
        and not_change(service, :date_updated)
    end

    it 'only updates records for the specific enrollment' do
      other_enrollment = create(:hmis_hud_enrollment, client: from_client, project: project, data_source: data_source)
      other_service = create(:hmis_hud_service, enrollment: other_enrollment, client: from_client, data_source: data_source)
      expect do
        described_class.perform_now(enrollment_id: enrollment.id, to_client_id: to_client.id)
        [enrollment, other_enrollment, service, other_service].each(&:reload)
      end.to change(service, :personal_id).from(from_client.personal_id).to(to_client.personal_id).
        and not_change(other_enrollment, :personal_id).
        and not_change(other_service, :personal_id).
        and not_change(service, :date_updated).
        and not_change(other_service, :date_updated)
    end

    it 'handles dry run without making changes' do
      expect do
        described_class.perform_now(enrollment_id: enrollment.id, to_client_id: to_client.id, dry_run: true)
        [enrollment, service, assessment].each(&:reload)
      end.to not_change(enrollment, :personal_id).
        and not_change(service, :personal_id).
        and not_change(assessment, :personal_id)
    end
  end
end

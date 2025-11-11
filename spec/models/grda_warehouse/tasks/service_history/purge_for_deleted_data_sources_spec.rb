# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::ServiceHistory::PurgeForDeletedDataSources, type: :model do
  let(:dry_run) { false }
  let(:retain_at) { 1.day.ago }

  let!(:active_data_source) { create :source_data_source, name: 'Active Source' }
  let!(:deleted_data_source) { create :source_data_source, name: 'Deleted Source' }
  let!(:recently_deleted_data_source) { create :source_data_source, name: 'Recently Deleted' }

  let(:destination_data_source) { create :destination_data_source }

  def create_client_with_warehouse_link(data_source:, dob: '2000-01-01')
    source_client = create(:grda_warehouse_hud_client, data_source: data_source, DOB: dob)
    destination_client = source_client.dup
    destination_client.data_source = destination_data_source
    destination_client.save!
    create(:warehouse_client, destination_id: destination_client.id, source_id: source_client.id)
    source_client
  end

  def create_enrollment_with_service_history(data_source:, client:)
    organization = create(:hud_organization, data_source: data_source)
    project = create(:grda_warehouse_hud_project, data_source: data_source, organization: organization, project_type: 0)

    enrollment = create(
      :grda_warehouse_hud_enrollment,
      data_source: data_source,
      project: project,
      client: client,
      entry_date: '2023-01-01',
    )

    create(
      :hud_exit,
      data_source_id: data_source.id,
      EnrollmentID: enrollment.EnrollmentID,
      PersonalID: client.PersonalID,
      ExitDate: '2023-01-05',
    )

    # Build service history
    service_history_enrollment = GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(enrollment.id)
    service_history_enrollment.rebuild_service_history!

    enrollment
  end

  describe '.call' do
    context 'when there are no deleted data sources' do
      let!(:deleted_data_source) { nil }

      it 'returns zero counts' do
        result = described_class.call(dry_run: dry_run, retain_at: retain_at)
        expect(result[:enrollments_deleted]).to eq(0)
        expect(result[:services_deleted]).to eq(0)
      end
    end

    context 'when there are deleted data sources with service history' do
      let!(:active_client) { create_client_with_warehouse_link(data_source: active_data_source) }
      let!(:deleted_client) { create_client_with_warehouse_link(data_source: deleted_data_source) }
      let!(:recently_deleted_client) { create_client_with_warehouse_link(data_source: recently_deleted_data_source) }

      before do
        # Create service history for all three data sources
        create_enrollment_with_service_history(data_source: active_data_source, client: active_client)
        create_enrollment_with_service_history(data_source: deleted_data_source, client: deleted_client)
        create_enrollment_with_service_history(data_source: recently_deleted_data_source, client: recently_deleted_client)

        # Now soft-delete two of the data sources
        deleted_data_source.update_column(:deleted_at, 2.days.ago)
        recently_deleted_data_source.update_column(:deleted_at, 1.hour.ago)
      end

      it 'only purges service history for data sources deleted before retain_at' do
        # Verify initial state
        expect(GrdaWarehouse::ServiceHistoryEnrollment.where(data_source_id: active_data_source.id).count).to be > 0
        expect(GrdaWarehouse::ServiceHistoryEnrollment.where(data_source_id: deleted_data_source.id).count).to be > 0
        expect(GrdaWarehouse::ServiceHistoryEnrollment.where(data_source_id: recently_deleted_data_source.id).count).to be > 0

        result = described_class.call(dry_run: dry_run, retain_at: retain_at)

        # Active data source should retain service history
        expect(GrdaWarehouse::ServiceHistoryEnrollment.where(data_source_id: active_data_source.id).count).to be > 0
        expect(GrdaWarehouse::ServiceHistoryService.joins(:service_history_enrollment).where(
          service_history_enrollments: { data_source_id: active_data_source.id },
        ).count).to be > 0

        # Deleted data source (deleted 2 days ago) should have service history removed
        expect(GrdaWarehouse::ServiceHistoryEnrollment.where(data_source_id: deleted_data_source.id).count).to eq(0)
        expect(GrdaWarehouse::ServiceHistoryService.joins(:service_history_enrollment).where(
          service_history_enrollments: { data_source_id: deleted_data_source.id },
        ).count).to eq(0)

        # Recently deleted data source (deleted 1 hour ago, after retain_at) should retain service history
        expect(GrdaWarehouse::ServiceHistoryEnrollment.where(data_source_id: recently_deleted_data_source.id).count).to be > 0

        # Verify counts
        expect(result[:enrollments_deleted]).to be > 0
        expect(result[:services_deleted]).to be > 0
      end
    end

    context 'with dry_run enabled' do
      let(:dry_run) { true }
      let!(:client) { create_client_with_warehouse_link(data_source: deleted_data_source) }

      before do
        create_enrollment_with_service_history(data_source: deleted_data_source, client: client)
        # Soft-delete the data source after creating service history
        deleted_data_source.update_column(:deleted_at, 2.days.ago)
      end

      it 'counts but does not delete records' do
        initial_enrollment_count = GrdaWarehouse::ServiceHistoryEnrollment.where(data_source_id: deleted_data_source.id).count
        initial_service_count = GrdaWarehouse::ServiceHistoryService.joins(:service_history_enrollment).where(
          service_history_enrollments: { data_source_id: deleted_data_source.id },
        ).count

        expect(initial_enrollment_count).to be > 0
        expect(initial_service_count).to be > 0

        result = described_class.call(dry_run: dry_run, retain_at: retain_at)

        # Counts should be returned
        expect(result[:enrollments_deleted]).to eq(initial_enrollment_count)
        expect(result[:services_deleted]).to eq(initial_service_count)

        # But records should still exist
        expect(GrdaWarehouse::ServiceHistoryEnrollment.where(data_source_id: deleted_data_source.id).count).to eq(initial_enrollment_count)
        expect(GrdaWarehouse::ServiceHistoryService.joins(:service_history_enrollment).where(
          service_history_enrollments: { data_source_id: deleted_data_source.id },
        ).count).to eq(initial_service_count)
      end
    end

    context 'with multiple enrollments and services' do
      let!(:client1) { create_client_with_warehouse_link(data_source: deleted_data_source) }
      let!(:client2) { create_client_with_warehouse_link(data_source: deleted_data_source) }

      before do
        create_enrollment_with_service_history(data_source: deleted_data_source, client: client1)
        create_enrollment_with_service_history(data_source: deleted_data_source, client: client2)
        # Soft-delete the data source after creating service history
        deleted_data_source.update_column(:deleted_at, 2.days.ago)
      end

      it 'purges all service history for the deleted data source' do
        initial_enrollment_count = GrdaWarehouse::ServiceHistoryEnrollment.where(data_source_id: deleted_data_source.id).count
        expect(initial_enrollment_count).to be > 2 # At least entry + exit for each enrollment

        result = described_class.call(dry_run: dry_run, retain_at: retain_at)

        expect(GrdaWarehouse::ServiceHistoryEnrollment.where(data_source_id: deleted_data_source.id).count).to eq(0)
        expect(result[:enrollments_deleted]).to eq(initial_enrollment_count)
      end
    end
  end
end

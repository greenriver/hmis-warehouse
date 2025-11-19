# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HudSpmReport::Fy2026::EpisodeBatch, type: :model do
  include_context 'SPM test setup'

  let(:included_project_types) { [1] } # ES-NBN
  let(:excluded_project_types) { [] }
  let(:include_self_reported_and_ph) { false }

  describe '#calculate_batch' do
    it 'correctly filters services by data source and enrollment' do
      # Create project and client
      project = create_project(project_type: 1) # ES-NBN
      client = create_client_with_warehouse_link

      # Create a valid enrollment in the batch
      enrollment_in_batch = create_enrollment(
        client: client,
        project: project,
        entry_date: '2023-01-01'.to_date,
        exit_date: '2023-01-31'.to_date,
      )

      # Create a "ghost" enrollment for the same client but different data source
      # This simulates a collision in PersonalID across data sources
      other_data_source = create(:grda_warehouse_data_source)
      other_enrollment = create_enrollment(
        client: client,
        project: project,
        entry_date: '2023-01-01'.to_date,
        exit_date: '2023-01-31'.to_date,
      )
      # Manually override the data source to simulate the collision
      other_enrollment.update_column(:data_source_id, other_data_source.id)

      # Add bed nights for both
      # Valid bed night
      create_bed_night_service(
        enrollment: enrollment_in_batch,
        date: '2023-01-15'.to_date,
      )

      # Irrelevant bed night (same PersonalID, different Data Source)
      # We need to force this service to have the other data source ID
      s = create_bed_night_service(
        enrollment: other_enrollment,
        date: '2023-01-15'.to_date,
      )
      s.update_column(:data_source_id, other_data_source.id)

      # Setup a report instance (this populates SpmEnrollment)
      report = setup_report([project.id])

      # Create a SpmEnrollment scope for just the batch enrollment
      spm_enrollments = HudSpmReport::Fy2026::SpmEnrollment.where(
        enrollment_id: enrollment_in_batch.id,
      )

      # Ensure we have the correct client ID (from the SPM record)
      spm_client_id = spm_enrollments.first.client_id

      batch = described_class.new(
        spm_enrollments,
        included_project_types,
        excluded_project_types,
        include_self_reported_and_ph,
        report,
      )

      # Calculate using the correct client ID
      episodes = batch.calculate_batch([spm_client_id])

      expect(episodes.size).to eq(1)
      episode = episodes.first

      # It should have found the bed night for the batch enrollment
      expect(episode.days_homeless).to eq(1)
    end

    it 'filters out services for enrollments not in the batch (same client, same data source)' do
      project = create_project(project_type: 1)
      client = create_client_with_warehouse_link

      # Enrollment 1: In the batch
      enrollment_1 = create_enrollment(
        client: client,
        project: project,
        entry_date: '2023-01-01'.to_date,
        exit_date: '2023-01-10'.to_date,
      )
      create_bed_night_service(enrollment: enrollment_1, date: '2023-01-05'.to_date)

      # Enrollment 2: Same client, same project, but NOT in the batch (simulating filtered out enrollment)
      enrollment_2 = create_enrollment(
        client: client,
        project: project,
        entry_date: '2023-02-01'.to_date,
        exit_date: '2023-02-10'.to_date,
      )
      create_bed_night_service(enrollment: enrollment_2, date: '2023-02-05'.to_date)

      # Setup report AFTER creating enrollments
      report = setup_report([project.id])

      # Pass ONLY enrollment 1
      spm_enrollments = HudSpmReport::Fy2026::SpmEnrollment.where(enrollment_id: enrollment_1.id)

      # Ensure we have the correct client ID (from the SPM record)
      spm_client_id = spm_enrollments.first.client_id

      batch = described_class.new(
        spm_enrollments,
        included_project_types,
        excluded_project_types,
        include_self_reported_and_ph,
        report,
      )

      episodes = batch.calculate_batch([spm_client_id])

      expect(episodes.size).to eq(1)
      episode = episodes.first

      # Should only count the 1 day from enrollment 1
      expect(episode.days_homeless).to eq(1)
      expect(episode.first_date).to eq('2023-01-05'.to_date)
    end

    it 'handles empty batches gracefully' do
      project = create_project(project_type: 1)
      report = setup_report([project.id])

      spm_enrollments = HudSpmReport::Fy2026::SpmEnrollment.none

      batch = described_class.new(
        spm_enrollments,
        included_project_types,
        excluded_project_types,
        include_self_reported_and_ph,
        report,
      )

      expect(batch.calculate_batch([])).to eq([])
    end
  end
end

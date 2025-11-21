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
      project = create_project(project_type: 1) # ES-NBN
      client = create_client_with_warehouse_link

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

      create_bed_night_service(
        enrollment: enrollment_in_batch,
        date: '2023-01-15'.to_date,
      )

      # Irrelevant bed night (same PersonalID, different data source)
      # Force this service to have the other data source ID
      s = create_bed_night_service(
        enrollment: other_enrollment,
        date: '2023-01-15'.to_date,
      )
      s.update_column(:data_source_id, other_data_source.id)

      # Populates SpmEnrollment
      report = setup_report([project.id])

      spm_enrollments = HudSpmReport::Fy2026::SpmEnrollment.where(
        enrollment_id: enrollment_in_batch.id,
      )

      # Use SPM client ID, not warehouse client ID
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

      expect(episode.days_homeless).to eq(1)
    end

    it 'excludes bed nights after the report end date' do
      project = create_project(project_type: 1) # ES-NBN
      client = create_client_with_warehouse_link

      enrollment = create_enrollment(
        client: client,
        project: project,
        entry_date: '2022-01-01'.to_date,
        exit_date: '2024-12-31'.to_date,
      )

      # Bed nights within enrollment, before and after report end date (test report ends Sep 30, 2023)
      create_bed_night_service(enrollment: enrollment, date: '2023-09-29'.to_date)
      create_bed_night_service(enrollment: enrollment, date: '2023-09-30'.to_date) # Last day of report
      create_bed_night_service(enrollment: enrollment, date: '2023-10-01'.to_date) # After report end
      create_bed_night_service(enrollment: enrollment, date: '2024-06-15'.to_date) # After report end

      report = setup_report([project.id])

      spm_enrollments = HudSpmReport::Fy2026::SpmEnrollment.where(enrollment_id: enrollment.id)
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

      # Should count only the 2 bed nights before report end date
      expect(episode.days_homeless).to eq(2)
      expect(episode.first_date).to eq('2023-09-29'.to_date)
      expect(episode.last_date).to eq('2023-09-30'.to_date)
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

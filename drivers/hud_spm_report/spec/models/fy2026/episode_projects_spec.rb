###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_context'

RSpec.describe HudSpmReport::Fy2026::Episode, type: :model do
  include_context '2026 SPM test setup'

  let(:user) { create(:user) }
  let!(:project_a) { create_project(project_type: 0) }
  let!(:project_b) { create_project(project_type: 0) }
  let!(:client) { create_client_with_warehouse_link(first_name: 'Episode', last_name: 'Projects') }

  # Builds the SPM enrollment set for both projects without running a measure,
  # then hangs an episode off the given enrollments.
  def spm_enrollments_for(report)
    HudSpmReport::Fy2026::SpmEnrollment.where(report_instance_id: report.id).order(:entry_date, :id).to_a
  end

  def build_episode(spm_enrollments)
    episode = described_class.create!(
      client_id: spm_enrollments.first.client_id,
      first_date: '2022-11-01'.to_date,
      last_date: '2023-01-15'.to_date,
      days_homeless: 10,
    )
    spm_enrollments.each do |spm_enrollment|
      HudSpmReport::Fy2026::EnrollmentLink.create!(episode: episode, enrollment: spm_enrollment)
    end
    described_class.find(episode.id)
  end

  it 'lists each contributing project once, ordered by entry date' do
    create_enrollment(client: client, project: project_a, entry_date: '2022-11-01'.to_date, exit_date: '2022-12-15'.to_date)
    create_enrollment(client: client, project: project_b, entry_date: '2022-12-15'.to_date, exit_date: '2023-01-15'.to_date)
    report = setup_report([project_a.id, project_b.id], ['Measure 1'])

    episode = build_episode(spm_enrollments_for(report))

    expect(episode.projects).to eq([project_a, project_b])
    expect(episode.project_hmis_ids).to eq("#{project_a.ProjectID}; #{project_b.ProjectID}")
  end

  it 'deduplicates two enrollments in the same project' do
    create_enrollment(client: client, project: project_a, entry_date: '2022-11-01'.to_date, exit_date: '2022-12-01'.to_date)
    create_enrollment(client: client, project: project_a, entry_date: '2022-12-01'.to_date, exit_date: '2023-01-15'.to_date)
    report = setup_report([project_a.id], ['Measure 1'])

    spm_enrollments = spm_enrollments_for(report)
    expect(spm_enrollments.size).to eq(2)

    episode = build_episode(spm_enrollments)

    expect(episode.projects).to eq([project_a])
    expect(episode.project_hmis_ids).to eq(project_a.ProjectID)
  end

  it 'returns an empty array when the enrollment has no resolvable project' do
    create_enrollment(client: client, project: project_a, entry_date: '2022-11-01'.to_date, exit_date: '2023-01-15'.to_date)
    report = setup_report([project_a.id], ['Measure 1'])

    spm_enrollments = spm_enrollments_for(report)
    # Simulate orphaned source data: the enrollment points at a ProjectID that
    # no longer exists, so the project association resolves to nil.
    spm_enrollments.first.enrollment.update_columns(ProjectID: 'no-such-project')

    episode = build_episode(spm_enrollments)

    expect(episode.projects).to eq([])
    expect(episode.project_hmis_ids).to eq('')
  end
end

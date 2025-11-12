###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../../spec/shared_contexts/hud_enrollment_builders'

# Shared context for DQ Tool testing
RSpec.shared_context 'DQ Tool test setup', shared_context: :metadata do
  include_context 'HUD enrollment builders'

  # Ensure data sources are created (they're defined in HUD enrollment builders, but ensure they exist)
  let!(:destination_data_source) { create :destination_data_source }
  let!(:data_source) { create(:source_data_source) }
  let!(:organization) { create(:hud_organization, data_source: data_source) }

  # Grant user permission to view all reports (which allows viewing all projects for reporting)
  let(:user_with_client_access) { create(:acl_user) }
  let!(:report_role) do
    create(:role,
           name: 'DQ Tool Test Role - Full Access',
           can_view_project_related_filters: true,
           can_view_assigned_reports: true,
           can_view_projects: true,
           can_view_clients: true,
           can_search_own_clients: true)
  end
  let(:data_sources_collection) { Collection.system_collection(:data_sources) }
  # Ensure user has the report role before filters are created
  before do
    setup_access_control(user_with_client_access, report_role, data_sources_collection)
    # Clear user permission cache to ensure changes take effect
    # user.clear_memery_cache!
  end

  let(:default_filter) do
    Filters::HudFilterBase.new(
      user_id: user_with_client_access.id,
      start: '2022-10-01'.to_date,
      end: '2023-09-30'.to_date,
      coc_codes: ['MA-500'],
      enforce_one_year_range: false,
      dates_to_compare: :date_to_street_to_entry,
      require_service_during_range: false,
    )
  end

  # Override create_enrollment to provide defaults and ensure creation of certain fields used in DQ tests
  def create_enrollment(client:, project:, entry_date: '2023-01-15'.to_date, exit_date: '2023-03-15'.to_date, relationship_to_ho_h: 1, date_to_street_essh: '2023-01-20'.to_date, household_id: 'test_household', living_situation: nil, destination: nil, move_in_date: nil)
    enrollment_attrs = {
      client: client,
      project: project,
      data_source: data_source,
      entry_date: entry_date,
      date_to_street_essh: date_to_street_essh,
      relationship_to_ho_h: relationship_to_ho_h,
      household_id: household_id,
      move_in_date: move_in_date,
      enrollment_coc: project.project_cocs.min_by(&:id).coc_code,
      DateCreated: entry_date, # Always set DateCreated
    }
    # Use LivingSituation (capitalized) for HUD field name
    enrollment_attrs[:LivingSituation] = living_situation if living_situation.present?
    enrollment = create(:hud_enrollment, enrollment_attrs)

    if exit_date.present?
      create(
        :hud_exit,
        enrollment: enrollment,
        exit_date: exit_date,
        data_source: data_source,
        personal_id: client.personal_id,
        destination: destination,
        DateCreated: exit_date, # Set DateCreated for exit as well
      )
    end

    enrollment
  end

  def setup_report(project_ids)
    filter = default_filter.dup
    filter.update(project_ids: project_ids)

    # Build ServiceHistoryEnrollments - required for report to find enrollments
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

    report = HmisDataQualityTool::Report.new(
      user_id: user_with_client_access.id,
      report_name: HmisDataQualityTool::Report.untranslated_title,
      manual: true,
      question_names: [],
    )
    report.filter = filter
    report.save!
    report.run_and_save!
    # Reload to ensure associations are fresh after populate_universe
    report.reload
    report
  end

  # Helper method to DRY up result checking
  def expect_result(title:, total: 1, invalid_count: 0, report: nil)
    report ||= @report
    result = report.results.find { |r| r.title == title }
    expect(result).to be_present
    expect(result.total).to eq(total)
    expect(result.invalid_count).to eq(invalid_count)
    result
  end
end
